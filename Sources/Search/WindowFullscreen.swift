import AppKit
import WebKit

// A page's full screen the way Chrome does it: the page never leaves this
// window. WebKit's own element full screen lends the page to a window of its
// own and gives it back behind a frozen picture, held until the page has
// drawn again in ours (240 to 400 ms on YouTube, measured 8 Nov 2026; a bare
// WKWebView holds it 80 ms, Safari 100 to 150). With Settings › Video › Full
// screen takes the window on (off unless asked for), WebKit's is switched off
// for tabs made after (Web.configuration), the page's Fullscreen API is
// answered by the script below, and the window itself goes full screen as
// macOS moves it, the chrome stepping aside as it always has for a page
// filling the screen (Tab.immersed).

final class WindowFullscreen: NSObject, WKScriptMessageHandler {
    static let name = "searchFullscreen"

    weak var tab: Tab?

    /// Whether this page's full screen took the window there, so that coming
    /// back gives it back; a window already full screen stays.
    private var tookWindow = false
    /// That window, for the way back once another tab is in front of the
    /// page (⌘T or ⌃Tab on the video, which also end its full screen,
    /// #1042) and the page is out of it.
    private weak var taken: NSWindow?
    private var exitWatch: NSObjectProtocol?

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let on = (message.body as? [String: Any])?["on"] as? Bool else { return }
        MainActor.assumeIsolated { set(on) }
    }

    @MainActor private func set(_ on: Bool) {
        guard let tab else { return }
        // Any script on the page can post here, past the script's own check
        // of the page's activation, so going in also needs a real click or
        // key press in the last second, as Search's own world saw it.
        // Refused, the page is told it is out. Coming back always goes.
        if on, !tab.popupGesture.recent() {
            tab.built?.evaluateJavaScript(Self.exit, in: nil, in: .page)
            return
        }
        guard let window = tab.built?.window ?? (on ? nil : taken) else {
            if tab.immersed != on { tab.immersed = on }
            return
        }
        let full = window.styleMask.contains(.fullScreen)
        if tab.immersed != on { tab.immersed = on }
        if on {
            watchExit(of: window)
            if !full {
                tookWindow = true
                taken = window
                window.toggleFullScreen(nil)
            }
        } else {
            stopWatching()
            if tookWindow, full { window.toggleFullScreen(nil) }
            tookWindow = false
            taken = nil
        }
        tab.built?.evaluateJavaScript(Self.tell, in: nil, in: .page)
    }

    /// A new document in the tab: the page that asked is gone, and its full
    /// screen with it, or the window stays there with the chrome away and
    /// nothing left to bring it back.
    @MainActor func pageLeft() {
        if exitWatch != nil { set(false) }
    }

    /// The window leaving full screen some other way (the green button,
    /// ⌃⌘F, Mission Control) takes the page out of its full screen too.
    @MainActor private func watchExit(of window: NSWindow) {
        stopWatching()
        exitWatch = NotificationCenter.default.addObserver(
            forName: NSWindow.willExitFullScreenNotification, object: window, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.tookWindow = false
                self.tab?.built?.evaluateJavaScript(Self.exit, in: nil, in: .page)
            }
        }
    }

    @MainActor private func stopWatching() {
        if let exitWatch { NotificationCenter.default.removeObserver(exitWatch) }
        exitWatch = nil
    }

    static let exit = "window.__searchFullscreen && window.__searchFullscreen.exit(); 0"
    static let tell = "window.__searchFullscreen && window.__searchFullscreen.tell(); 0"

    /// In the page's own world, where its players call the API. The element
    /// asked for is put in the top layer (a manual popover), out from under
    /// any transform, overflow or z-index around it, and pinned to the
    /// viewport, which the window then grows to the whole screen. `:fullscreen`
    /// itself can't be made to match; YouTube styles its player by its own
    /// attributes, so it doesn't look.
    static let script = """
    (function () {
      if (window.__searchFullscreen) return;
      var current = null;
      var css = document.createElement('style');
      css.textContent =
        '[data-search-fullscreen]{position:fixed!important;inset:0!important;width:100%!important;height:100%!important;' +
        'max-width:none!important;max-height:none!important;min-width:0!important;min-height:0!important;' +
        'margin:0!important;padding:0!important;border:0!important;box-sizing:border-box!important;' +
        'transform:none!important;z-index:2147483647!important;background:#000;overflow:hidden!important}' +
        '[data-search-fullscreen]::backdrop{background:#000}';
      function post(on) {
        try { window.webkit.messageHandlers.searchFullscreen.postMessage({ on: on }); } catch (e) {}
      }
      function fire(el) {
        setTimeout(function () {
          var target = el.isConnected ? el : document;
          target.dispatchEvent(new Event('fullscreenchange', { bubbles: true, composed: true }));
          target.dispatchEvent(new Event('webkitfullscreenchange', { bubbles: true, composed: true }));
        }, 0);
      }
      function enter(el) {
        if (navigator.userActivation && !navigator.userActivation.isActive && !current) {
          return Promise.reject(new TypeError('Full screen needs a click or a key press.'));
        }
        if (current === el) return Promise.resolve();
        if (current) leave();
        current = el;
        post(true);
        later(el);
        return Promise.resolve();
      }
      // The element pinned to the viewport: the whole document (YouTube's
      // choice) already has it, which the window then grows.
      function pin(el) {
        if (el !== current || el === document.documentElement) return;
        (document.head || document.documentElement).appendChild(css);
        el.setAttribute('data-search-fullscreen', '');
        if (typeof el.showPopover === 'function' && !el.hasAttribute('popover')) {
          el.setAttribute('popover', 'manual');
          try { el.showPopover(); el.__searchPopover = true; } catch (e) { el.removeAttribute('popover'); }
        }
      }
      function leave() {
        if (!current) return Promise.resolve();
        var el = current;
        current = null;
        if (el.__searchPopover) {
          try { el.hidePopover(); } catch (e) {}
          el.removeAttribute('popover');
          delete el.__searchPopover;
        }
        el.removeAttribute('data-search-fullscreen');
        post(false);
        later(el);
        return Promise.resolve();
      }
      // Each way, the change is said (and the element pinned) once Search has
      // set the window moving (tell, from Search), or after 0.4 s if Search
      // never answers: said at the request, YouTube laid its player out for
      // the window it was leaving, a step of its own before the move.
      var told = null;
      function later(el) {
        told = el;
        setTimeout(tell, 400);
      }
      function tell() {
        if (!told) return;
        var el = told;
        told = null;
        pin(el);
        fire(el);
      }
      var E = Element.prototype, D = Document.prototype;
      E.requestFullscreen = function () { return enter(this); };
      E.webkitRequestFullscreen = E.webkitRequestFullScreen = function () { enter(this); };
      D.exitFullscreen = function () { return leave(); };
      D.webkitExitFullscreen = D.webkitCancelFullScreen = function () { leave(); };
      function getter(name, get) { Object.defineProperty(D, name, { get: get, configurable: true }); }
      ['fullscreenElement', 'webkitFullscreenElement', 'webkitCurrentFullScreenElement'].forEach(function (n) {
        getter(n, function () { return current; });
      });
      ['fullscreen', 'webkitIsFullScreen'].forEach(function (n) { getter(n, function () { return !!current; }); });
      ['fullscreenEnabled', 'webkitFullscreenEnabled'].forEach(function (n) { getter(n, function () { return true; }); });
      // Players pick the event to listen for by which handler property
      // exists ("onfullscreenchange" in document); with WebKit's own full
      // screen off, none does, and YouTube never heard it had gone in.
      ['fullscreenchange', 'fullscreenerror', 'webkitfullscreenchange', 'webkitfullscreenerror'].forEach(function (type) {
        var prop = 'on' + type;
        [D, E].forEach(function (proto) {
          if (prop in proto) return;
          var handlers = new WeakMap();
          Object.defineProperty(proto, prop, {
            configurable: true,
            get: function () { return handlers.get(this) || null; },
            set: function (fn) {
              var old = handlers.get(this);
              if (old) this.removeEventListener(type, old);
              if (typeof fn === 'function') { handlers.set(this, fn); this.addEventListener(type, fn); }
              else handlers.delete(this);
            }
          });
        });
      });
      // Escape ends the full screen and goes no further, as WebKit's own
      // never reaches the page: left to go on, AppKit took a window that
      // was full screen already (the green button) out of it as well.
      document.addEventListener('keydown', function (e) {
        if (current && e.key === 'Escape') { e.preventDefault(); e.stopImmediatePropagation(); leave(); }
      }, true);
      Object.defineProperty(window, '__searchFullscreen', { value: { exit: leave, tell: tell } });
    })();
    """
}
