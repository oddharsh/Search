import SwiftUI
import AppKit

/// One field, high up as Spotlight's is, and the few places it thinks you
/// mean. It takes addresses and only addresses: type something that isn't a
/// place and it shivers and says so, rather than quietly handing your
/// keystrokes to a search engine.
struct Omnibox: View {
    @ObservedObject var browser: Browser
    /// Raised over a page by ⌘L, rather than standing on an empty tab.
    let over: Bool

    /// The field's own height — the 26 of text and 13 of air above and below
    /// it that `field` lays out — so the list can sit below it without being
    /// stacked with it, and the tabs under an empty pane know where it ends.
    static let fieldHeight: CGFloat = 26 + 13 * 2

    /// The panel's corners: half the field's height, so empty it is a
    /// capsule, and with a list the top stays where the capsule's was.
    private static let corner: CGFloat = fieldHeight / 2

    /// Where the field stands in a space `height` tall: a fifth of the way
    /// down, as Spotlight does on a screen, so the list has the rest to fall
    /// into. The middle left a long list running off the bottom.
    static func top(in height: CGFloat) -> CGFloat { max(24, (height * 0.2).rounded()) }

    /// How near home a field being dragged has to come to be pulled there,
    /// so that putting it back takes no aim.
    private static let snap: CGFloat = 20

    /// Where a field `width` wide, moved `moved` from its home in a space
    /// `room` big, stands: no nearer an edge than the 24 points `top(in:)`
    /// keeps above it, and home itself within `snap` of it.
    static func place(_ moved: CGSize, width: CGFloat, in room: CGSize) -> CGSize {
        let home = top(in: room.height)
        let across = max(0, (room.width - width) / 2 - 24)
        let up = max(0, home - 24), down = max(0, room.height - 24 - fieldHeight - home)
        let inside = CGSize(width: min(max(moved.width, -across), across),
                            height: min(max(moved.height, -up), down))
        return hypot(inside.width, inside.height) <= snap ? .zero : inside
    }

    /// Where the field over a page was last left, from its home, kept across
    /// launches as Spotlight and Raycast keep theirs; none while it is home.
    /// From its home rather than the window's corner, so a window made
    /// smaller or larger keeps it where it was in the page's terms, and
    /// `place` keeps it in the window.
    private static var kept: CGSize {
        get { Store.settings.string(forKey: "field.offset").map(NSSizeFromString) ?? .zero }
        set {
            let text = newValue == .zero ? nil : NSStringFromSize(newValue)
            Store.settings.set(text, forKey: "field.offset")
        }
    }

    @State private var shake: CGFloat = 0
    @State private var refused = false
    @State private var moved = Omnibox.kept
    /// Where it stands while it is being dragged.
    @State private var dragged: CGSize?

    /// Sized to a pane of a split rather than to the window.
    var fitted = false

    /// Over a page and not in a pane: the field you can move, by anything
    /// round its words. The words themselves are AppKit's, so a press there
    /// still goes to the text.
    private var movable: Bool { over && !fitted }

    private var listing: Bool { !browser.offers.isEmpty || browser.siteOffer != nil }

    var body: some View {
        GeometryReader { geometry in
            let width = fitted ? min(Metrics.fieldWidth, max(0, geometry.size.width - 28))
                : Metrics.fieldWidth
            content(width: width, room: geometry.size)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(browser.fieldShowing)
    }

    private func drag(width: CGFloat, room: CGSize) -> some Gesture {
        // In the window's terms: in the field's own, the ground under the
        // hand would move with it.
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { drag in
                let was = dragged ?? Self.place(moved, width: width, in: room)
                let now = Self.place(CGSize(width: moved.width + drag.translation.width,
                                            height: moved.height + drag.translation.height),
                                     width: width, in: room)
                guard (now == .zero) != (was == .zero) else { dragged = now; return }
                // Caught at home: said once, by touch, as the column says a
                // tab has crossed its line. Caught or let go, the jump is
                // eased rather than drawn in one frame.
                if now == .zero {
                    NSHapticFeedbackManager.defaultPerformer
                        .perform(.alignment, performanceTime: .now)
                }
                withAnimation(Motion.quick) { dragged = now }
            }
            .onEnded { _ in
                moved = dragged ?? moved
                dragged = nil
                Self.kept = moved
            }
    }

    private func content(width: CGFloat, room: CGSize) -> some View {
        ZStack(alignment: .top) {
            // Keep the container mounted: the field and what lies under it
            // come and go inside it.
            if browser.fieldShowing {
                if over {
                    // The page stays as it was, unwashed, as under Spotlight:
                    // the field floats over it. A click anywhere off the field
                    // still puts it away.
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea(.all, edges: fitted ? [] : .all)
                        .onTapGesture { browser.dismiss() }
                        .transition(.opacity)
                }

                field
                    .frame(width: width)
                    .contentShape(Rectangle())
                    .gesture(drag(width: width, room: room), including: movable ? .all : .subviews)
                    // The panel is the field's background, hanging below it, so
                    // a list that grows never lifts the field out from under
                    // what is being typed. Its rows are below the field, where
                    // nothing is in front of them, and take clicks there.
                    .background(alignment: .top) { panel(width: width) }
                    // A slow, almost invisible breath under the field. It is the
                    // only thing on an empty tab, and a thing that never moves at
                    // all reads as a picture of an app rather than an app. Gone
                    // while the list is up: a glow round the field alone would
                    // halo half the panel.
                    .background { if !listing { Breath() } }
                    .modifier(Shake(travel: shake))
                    .onAppear {
                        shake = 0
                        refused = false
                        // Where another window's field was last left, too.
                        moved = Self.kept
                    }
                    .onChange(of: browser.refusals) { _, _ in
                        shake = 0
                        refused = true
                        withAnimation(.easeOut(duration: 0.5)) { shake = 1 }
                    }
                    .onChange(of: browser.typed) { _, _ in
                        withAnimation(Motion.quick) { refused = false }
                    }
                    .padding(.top, Self.top(in: room.height))
                    .offset(movable ? dragged ?? Self.place(moved, width: width, in: room) : .zero)
                    // There and gone at once, as Spotlight's is: grown in on a
                    // spring, it showed as a grey box on its way to the capsule.
                    .transition(.identity)
                    // The list's arrival and its leaving are animated from here,
                    // briefly: nothing that changes the suggestions does it
                    // inside an animation of its own. Its rows follow what was
                    // typed or pasted at once — sliding into place on a spring
                    // between keystrokes, they trailed behind the field.
                    .animation(Motion.quick, value: listing)
                    .animation(Motion.settle, value: refused)
            }
        }
    }

    private var field: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.muted)
            if let site = browser.siteChip {
                SiteChip(site: site)
                    .transition(.scale(scale: 0.9, anchor: .leading).combined(with: .opacity))
            }
            AddressField(browser: browser)
        }
            .animation(Motion.quick, value: browser.siteChip)
            .frame(height: 26)
            .padding(.leading, 18)
            .padding(.trailing, 22)
            .padding(.vertical, 13)
    }

    /// The ground under the field and the list together: one shape, a
    /// capsule while the field is alone, taller once the list is in it.
    private func panel(width: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
        return VStack(spacing: 0) {
            Color.clear.frame(height: Self.fieldHeight)
            if listing {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    list
                }
                .transition(.opacity)
            }
        }
        .frame(width: width)
        // As tall as it needs to be, not the field's height it is offered.
        .fixedSize(horizontal: false, vertical: true)
        .background(Palette.ground, in: shape)
        .overlay(
            shape
                .strokeBorder(refused ? Color.red.opacity(0.35) : Palette.hairline, lineWidth: 1)
                .allowsHitTesting(false)
        )
        // Flat, as a sheet of paper is: the hairline is what sets it apart
        // from the page, and the shadow only just lifts it. Spotlight's
        // depth is its glass's, and there is no glass here.
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }

    /// What it thinks you mean. Places you have been come with their titles;
    /// the handful of well-known addresses it starts life knowing come without
    /// the weight of one.
    ///
    /// It lives in the panel below the field, so arriving or leaving never
    /// moves the field.
    private var list: some View {
        VStack(spacing: 0) {
            if let site = browser.siteOffer {
                SiteOfferRow(site: site)
                    .contentShape(Rectangle())
                    .onTapGesture { _ = browser.lockSiteOffer() }
            }
            ForEach(Array(browser.offers.enumerated()), id: \.element.id) { index, offer in
                Row(offer: offer, picked: browser.picked == index)
                    .contentShape(Rectangle())
                    .onTapGesture { browser.take(offer) }
            }
        }
        .padding(8)
    }

    /// One row of a list of places, here and under the field in the tab.
    struct Row: View {
        let offer: Suggestion
        /// Where the arrow keys have walked to. The pointer gets its own,
        /// quieter mark, and changes nothing but the look of the row.
        let picked: Bool

        @State private var hovering = false

        /// The row's name, on top, and what goes under it. A place keeps its
        /// name in the title and its address in the key; an open tab and a
        /// search are the other way round: the tab's name over its address,
        /// the words over the engine that answers them. The address reads as
        /// 1.0.4's did, without the www; the key itself keeps it, for
        /// completing and going there.
        static func lines(_ offer: Suggestion) -> (top: String, under: String) {
            let key = offer.kind == .suggested ? offer.key : Address.withoutWWW(offer.key)
            switch offer.kind {
            case .visited, .known, .bookmark:
                return offer.title.isEmpty ? (key, "") : (offer.title, key)
            case .open, .search, .suggested, .command:
                return (key, offer.title)
            }
        }

        var body: some View {
            HStack(spacing: 10) {
                switch offer.kind {
                case .search, .visited, .known:
                    // The engine's own icon when this Mac already has it: a
                    // search sent to a site you have been to says so with the
                    // site rather than a magnifying glass. Nothing is fetched
                    // for one that isn't known; the glass is what the row
                    // wears until then, and a place a globe, so every row's
                    // words start at the same edge.
                    if let icon = Favicons.shared.cached(for: offer.url) {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    } else {
                        Image(systemName: offer.kind == .search ? "magnifyingglass" : "globe")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.muted)
                            .frame(width: 16)
                    }
                case .suggested:
                    // The engine's own words: always the glass, so they read
                    // as searches rather than places.
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .frame(width: 16)
                case .open:
                    // Already open: naming it takes you back to it rather than
                    // opening a second copy.
                    Circle()
                        .fill(Palette.ink.opacity(0.55))
                        .frame(width: 5, height: 5)
                        .frame(width: 16)
                case .bookmark:
                    // Kept by you, not only visited: the bookmark's mark,
                    // as quiet as the command's.
                    Image(systemName: "bookmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .frame(width: 16)
                case .command:
                    Image(systemName: "command")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .frame(width: 16)
                }
                // As Spotlight lists things: the name, and under it where
                // it is.
                let lines = Self.lines(offer)
                VStack(alignment: .leading, spacing: 1) {
                    if !offer.title.isEmpty {
                        Text(lines.top)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(lines.under)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Palette.muted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text(lines.top)
                            .font(.system(size: 13.5))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 22)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                if picked {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Palette.wash)
                } else if hovering {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Palette.hover)
                }
            }
            .onHover { hovering = $0 }
            .animation(Motion.quick, value: hovering)
        }
    }
}

/// A site's icon when this Mac has it, or a glass.
private struct SiteIcon: View {
    let site: SearchSite
    var body: some View {
        let host = site.host.split(separator: "/").first.map(String.init) ?? site.host
        if let icon = Favicons.shared.cached(host) ?? Favicons.shared.cached("www." + host) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 14, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Palette.muted)
                .frame(width: 14, height: 14)
        }
    }
}

/// The site Tab put in the field: its icon and name, in the field's grey,
/// before what is typed.
private struct SiteChip: View {
    let site: SearchSite
    var body: some View {
        HStack(spacing: 6) {
            SiteIcon(site: site)
            Text(site.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Palette.wash, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Searching \(site.name)")
    }
}

/// "Search Reddit", first in the list, with the key that takes it.
private struct SiteOfferRow: View {
    let site: SearchSite
    @State private var hovering = false
    var body: some View {
        HStack(spacing: 10) {
            SiteIcon(site: site)
            Text("Search \(site.name)")
                .font(.system(size: 13))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("Tab")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Palette.muted)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Palette.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            if hovering { RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Palette.hover) }
        }
        .onHover { hovering = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Search \(site.name), press Tab")
    }
}

/// The breath under the field: a soft shape of ink, blurred, moved by Core
/// Animation. Animated by SwiftUI, it was drawn again on the main thread
/// every frame for as long as an empty tab was showing — 18% of a core with
/// the window doing nothing (24 Sep 2026). As a layer's shadow, breathed by
/// Core Animation, it is played in the render server and costs the app
/// nothing; and it is a layer, not a second SwiftUI view to build before
/// the first frame.
private struct Breath: NSViewRepresentable {
    /// As dark as the shape it replaces, 5% ink blurred by 26: a shadow of
    /// the same radius comes out at 0.7 of the darkness at equal strength,
    /// measured on pictures of both (24 Sep 2026), so 7%.
    static let strength: Swift.Float = 0.07

    func makeNSView(context: Context) -> NSView { Lung() }
    func updateNSView(_ view: NSView, context: Context) {}

    private final class Lung: NSView {
        private let glow = CALayer()
        private var breathed: CGSize = .zero

        override init(frame: NSRect) {
            super.init(frame: frame)
            wantsLayer = true
            glow.shadowOpacity = Breath.strength
            glow.shadowOffset = .zero
            glow.shadowRadius = 26
            layer?.addSublayer(glow)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        /// The ink is the look's: light on a dark window, dark on a light one.
        override func viewDidChangeEffectiveAppearance() {
            super.viewDidChangeEffectiveAppearance()
            effectiveAppearance.performAsCurrentDrawingAppearance { glow.shadowColor = Palette.NS.ink.cgColor }
        }

        override func layout() {
            super.layout()
            guard bounds.size != breathed, bounds.width > 0 else { return }
            breathed = bounds.size
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            glow.bounds = bounds
            glow.position = CGPoint(x: bounds.midX, y: bounds.midY)
            glow.shadowPath = CGPath(roundedRect: bounds, cornerWidth: 26, cornerHeight: 26, transform: nil)
            effectiveAppearance.performAsCurrentDrawingAppearance { glow.shadowColor = Palette.NS.ink.cgColor }
            CATransaction.commit()
            // From 0.97 to 1.03, from 0.65 to full, 2.6 s each way, for as
            // long as the field is there.
            let size = CABasicAnimation(keyPath: "transform.scale")
            size.fromValue = 0.97
            size.toValue = 1.03
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.65
            fade.toValue = 1.0
            let both = CAAnimationGroup()
            both.animations = [size, fade]
            both.duration = 2.6
            both.autoreverses = true
            both.repeatCount = .infinity
            both.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            glow.add(both, forKey: "breath")
        }
    }
}

/// The field itself, in AppKit.
///
/// SwiftUI's TextField can hold a string and nothing else, and the whole point
/// here is the part you didn't type: the rest of the address, already there and
/// selected, so carrying on typing replaces it and Return accepts it. That
/// needs a real text field and its delegate.
struct AddressField: NSViewRepresentable {
    @ObservedObject var browser: Browser

    func makeCoordinator() -> Coordinator { Coordinator(browser: browser) }

    func makeNSView(context: Context) -> Field {
        let field = Field()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 20)
        field.textColor = Palette.NS.ink
        field.lineBreakMode = .byClipping
        field.cell?.usesSingleLineMode = true
        field.cell?.wraps = false
        // Scrolls with the caret, so a long address can be read and edited
        // all the way along rather than cut off at the field's edge.
        field.cell?.isScrollable = true
        // SwiftUI picks its own colour for a placeholder, and on a pale ground
        // that colour was near-white.
        field.placeholderAttributedString = NSAttributedString(
            string: "Enter a web address",
            attributes: [
                .font: NSFont.systemFont(ofSize: 20),
                .foregroundColor: NSColor(Palette.ink.opacity(0.3)),
            ]
        )
        return field
    }

    func updateNSView(_ field: Field, context: Context) {
        let coordinator = context.coordinator
        coordinator.browser = browser

        // Only when something other than typing changed it — ⌘L arriving with
        // an address, a walk through the list, a submit clearing it.
        //
        // Comparing against the field's own text instead would undo every
        // backspace: deleting leaves the field shorter than what the browser
        // still considers complete, and the next update would helpfully type
        // it back in. That is a field you cannot shorten, and it reads exactly
        // like one that has stopped responding.
        let want = browser.completed
        if want != coordinator.synced {
            coordinator.synced = want
            field.stringValue = want
            coordinator.select(from: browser.typed.count, in: field)
        }

        if coordinator.answered != browser.focusRequest {
            coordinator.answered = browser.focusRequest
            DispatchQueue.main.async { coordinator.focus(field) }
        }
    }

    /// The field, told when it lands in a window.
    ///
    /// SwiftUI makes the view and updates it before it is in one, and with
    /// Split View on it comes only once the stage has said where the page is,
    /// a turn of the run loop later. Asked for the keys before then, the
    /// field had no window to ask: the request went nowhere and nothing asked
    /// again, so ⌘T left a field with no caret and typing that went nowhere
    /// until it was clicked. Now the request waits for the window.
    final class Field: NSTextField {
        var arrived: (() -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil, let arrived else { return }
            self.arrived = nil
            arrived()
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var browser: Browser
        var answered = -1
        /// The last value pushed in from the browser side, so an update can
        /// tell a change worth applying from one it made itself.
        var synced = ""

        /// A backspace has to be allowed to actually take a letter off. Without
        /// this the field puts the same letter straight back as a completion
        /// and the address can never be shortened.
        private var deleting = false

        init(browser: Browser) {
            self.browser = browser
        }

        /// The keys to the field, now if it is in a window, or the moment it is.
        @MainActor func focus(_ field: Field) {
            guard let window = field.window else {
                field.arrived = { [weak self, weak field] in
                    DispatchQueue.main.async {
                        guard let self, let field, self.browser.fieldShowing else { return }
                        self.focus(field)
                    }
                }
                return
            }
            field.arrived = nil
            window.makeFirstResponder(field)
            guard let editor = field.currentEditor() as? NSTextView else { return }
            defer { browser.fieldFocused(in: window) }
            // The system paints selected text as a block of accent colour,
            // which over this pale field is the loudest thing in the
            // window. A tenth of the ink says "selected" quietly enough.
            editor.selectedTextAttributes = [
                .backgroundColor: NSColor(Palette.ink.opacity(0.12)),
                .foregroundColor: Palette.NS.ink,
            ]
            // A draft come back to its blank tab is carried on, not typed
            // over: the caret after it. An address ⌘L raises is selected whole.
            if browser.active?.isBlank == true, !browser.typed.isEmpty {
                select(from: browser.typed.count, in: field)
            } else {
                editor.selectAll(nil)
            }
        }

        func controlTextDidChange(_ note: Notification) {
            guard let field = note.object as? NSTextField else { return }
            let text = field.stringValue

            browser.typed = text
            guard !deleting, let ending = browser.ending else {
                if deleting { browser.stopCompleting() }
                deleting = false
                synced = browser.completed
                return
            }
            deleting = false

            field.stringValue = text + ending
            synced = field.stringValue
            select(from: text.count, in: field)
        }

        /// The part after the caret, shown as selected, so the next keystroke
        /// replaces it and Return takes it.
        func select(from start: Int, in field: NSTextField) {
            guard let editor = field.currentEditor() as? NSTextView else { return }
            editor.selectedTextAttributes = [
                .backgroundColor: NSColor(Palette.ink.opacity(0.12)),
                .foregroundColor: Palette.NS.ink,
            ]
            let length = field.stringValue.count
            guard start <= length else { return }
            editor.selectedRange = NSRange(location: start, length: length - start)
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy command: Selector
        ) -> Bool {
            switch command {
            case #selector(NSResponder.insertNewline(_:)):
                browser.submit()
                return true
            case #selector(NSResponder.moveDown(_:)):
                browser.walk(1)
                return true
            case #selector(NSResponder.moveUp(_:)):
                browser.walk(-1)
                return true
            case #selector(NSResponder.deleteWordBackward(_:)):
                // ⌥⌫ over an offered ending lets go of it and takes the last
                // word typed, as it does with no ending there. Left to the
                // text view it would only take the selected ending.
                deleting = true
                let selected = textView.selectedRange()
                guard browser.ending != nil, selected.length > 0,
                      NSMaxRange(selected) == (textView.string as NSString).length
                else { return false }
                textView.delete(nil)
                deleting = true
                textView.deleteWordBackward(nil)
                return true
            case #selector(NSResponder.deleteBackward(_:)) where textView.string.isEmpty && browser.siteChip != nil:
                // ⌫ on an empty field takes the site out of it.
                browser.siteChip = nil
                return true
            case #selector(NSResponder.deleteBackward(_:)),
                 #selector(NSResponder.deleteForward(_:)),
                 #selector(NSResponder.deleteWordForward(_:)):
                deleting = true
                return false
            default:
                return false
            }
        }
    }
}
