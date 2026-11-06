import AppKit
import SwiftUI

// Settings › Flags, in a stack build: Search as upstream's main has it, with
// pull requests merged on top by stack.sh, including the ones upstream
// closed. The page lists each, says where it stands upstream, and gives it
// its switch when it has one, so a feature that never landed can still be
// turned off without a rebuild.
//
// stack.sh writes the list (StackManifest.swift) after the merges, naming
// only the settings of the pull requests in that build. Outside a stack the
// list is empty and the page isn't shown.

enum Stack {}

struct StackFeature: Identifiable {
    enum Status {
        /// Open upstream, waiting for review.
        case open
        /// Closed upstream without merging.
        case closed
        /// Closed after upstream took part of it by hand.
        case partlyLanded
        /// Never a pull request: the stack's own.
        case custom

        var label: String {
            switch self {
            case .open: return "Open"
            case .closed: return "Closed, not merged"
            case .partlyLanded: return "Partly landed"
            case .custom: return "Stack only"
            }
        }
    }

    let number: Int
    let title: String
    let status: Status
    /// Its own on/off setting, when it has one.
    var toggle: ReferenceWritableKeyPath<Preferences, Bool>? = nil
    /// Where its setting lives, when that isn't a plain switch.
    var page: SettingsPanel.Page? = nil

    var id: Int { number }
    var url: URL? { number > 0 ? URL(string: "https://github.com/driceroland/Search/pull/\(number)") : nil }
}

struct FlagsPage: View {
    @ObservedObject var prefs: Preferences
    /// To another settings page, for a feature whose setting lives there.
    let go: (SettingsPanel.Page) -> Void

    /// What upstream won't ship first: those are the ones only this build has.
    private var gone: [StackFeature] { Stack.features.filter { $0.status != .open } }
    private var waiting: [StackFeature] { Stack.features.filter { $0.status == .open } }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Upstream's main at \(Stack.base), with \(Stack.features.count) pull requests on top, merged \(Stack.date). A feature with a switch can be turned off here; a fix without one is simply in.")
                .font(.system(size: 11.5))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            group("Not in upstream", gone)
            group("Waiting for review", waiting)
        }
    }

    @ViewBuilder
    private func group(_ caption: String, _ features: [StackFeature]) -> some View {
        if !features.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Caption(caption)
                Card {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        if index > 0 { Rule() }
                        Line(feature.title, detail(feature)) { control(feature) }
                    }
                }
            }
        }
    }

    private func detail(_ feature: StackFeature) -> String {
        feature.number > 0 ? "#\(feature.number) · \(feature.status.label)" : feature.status.label
    }

    @ViewBuilder
    private func control(_ feature: StackFeature) -> some View {
        HStack(spacing: 10) {
            if let url = feature.url {
                Button { NSWorkspace.shared.open(url) } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                }
                .buttonStyle(.plain)
                .help("The pull request on GitHub")
            }
            if let path = feature.toggle {
                Switch(on: Binding(get: { prefs[keyPath: path] }, set: { prefs[keyPath: path] = $0 }))
            } else if let page = feature.page {
                Button(page.title) { go(page) }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.ink)
                    .help("Its setting is in \(page.title)")
            }
        }
    }
}
