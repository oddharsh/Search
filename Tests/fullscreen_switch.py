#!/usr/bin/env python3
"""Full screen takes the window: what a tab carries with the switch off and
on, in a hidden probe.

Build first (`./build.sh`), then `python3 Tests/fullscreen_switch.py`. A
hidden probe in a world of its own (split_view.py's harness). Off, as it is
unless asked for, a tab is as before: WebKit's own full screen, and no
script of Search's in the page nor a handler for one. On, a tab answers the
page's Fullscreen API itself, and a page that asks with no click or key
press behind it, its own check of its activation faked, is told it is out
and the window stays: any script on a page can reach the handler. Nothing
goes full screen: a video going there after a click, and coming back, are
checked by hand on a visible build.
"""
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import split_view as sv  # noqa: E402

sv.use("fullscreen-switch")

CARRIES = """JSON.stringify({
  handler: !!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.searchFullscreen),
  script: typeof window.__searchFullscreen,
  native: Element.prototype.requestFullscreen.toString().indexOf('[native code]') >= 0,
  enabled: document.fullscreenEnabled === true
})"""

# A page past the script's check: its activation said to be live, then the
# request, as a page that wanted the screen unasked could.
UNASKED = """Object.defineProperty(navigator, 'userActivation', { value: { isActive: true }, configurable: true });
document.documentElement.requestFullscreen(); 1"""


def carries(tab):
    return json.loads(sv.ev(tab, CARRIES))


def full():
    return sv.cmd({"do": "probe"})["cards"]["windowFullScreen"]


if __name__ == "__main__":
    t = sv.T()
    try:
        sv.setup()
        sv.launch()
        off = carries(sv.page("off"))
        t.ok("off: no handler for the page's full screen", off["handler"] is False, off)
        t.ok("off: no script of Search's in the page", off["script"] == "undefined", off)
        t.ok("off: the page's requestFullscreen is WebKit's own", off["native"] is True, off)
        t.ok("off: WebKit's full screen is on", off["enabled"] is True, off)

        sv.setup(**{"fullscreen.zoomsWindow": True})
        sv.launch()
        tab = sv.page("on")
        on = carries(tab)
        t.ok("on: the handler is there", on["handler"] is True, on)
        t.ok("on: Search's script answers the page", on["script"] == "object" and on["native"] is False, on)
        sv.ev(tab, UNASKED)
        time.sleep(1.5)
        t.ok("on: asked with no click or key, the window stays", full() is False)
        t.ok("…and the page is told it is out", sv.ev(tab, "document.fullscreenElement === null") is True)
    finally:
        sv.finish()
        t.done()
        sys.exit(1 if t.failed else 0)
