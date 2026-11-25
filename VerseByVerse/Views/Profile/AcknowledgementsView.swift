//
//  AcknowledgementsView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/26.
//

import SwiftUI

/// A third-party component the app ships, with its license text bundled
/// from `VerseByVerse/Licenses/`. The license files must ship with the app:
/// MIT, ISC and the SIL OFL all require the notice to travel with every copy.
struct Acknowledgement: Identifiable, Hashable {
    let name: String
    /// What it's used for, shown under the name.
    let usage: String
    let licenseName: String
    let url: URL
    /// Bundle resource name (without `.txt`) of the full license text.
    let licenseFile: String

    var id: String {
        licenseFile
    }

    /// Whether the project link is a GitHub repository (shown with the GitHub icon).
    var isGitHub: Bool {
        url.host() == "github.com"
    }

    /// The bundled license text, or `nil` when the file is missing from the
    /// bundle (pinned by `AcknowledgementTests`).
    var licenseText: String? {
        guard let fileURL = Bundle.main.url(forResource: licenseFile, withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    // swiftlint:disable force_unwrapping
    /// Everything the app bundles. Add an entry (and its license file in
    /// `VerseByVerse/Licenses/`) whenever a package, font or icon set is added.
    static let all: [Self] = [
        Self(name: "Lucide",
             usage: "Icons",
             licenseName: "ISC License",
             url: URL(string: "https://lucide.dev")!,
             licenseFile: "LICENSE-lucide"),
        Self(name: "swift-fsrs",
             usage: "Review scheduling",
             licenseName: "MIT License",
             url: URL(string: "https://github.com/open-spaced-repetition/swift-fsrs")!,
             licenseFile: "LICENSE-swift-fsrs"),
        Self(name: "Montserrat",
             usage: "Font",
             licenseName: "SIL Open Font License 1.1",
             url: URL(string: "https://github.com/JulietaUla/Montserrat")!,
             licenseFile: "LICENSE-montserrat"),
        Self(name: "Funnel Sans",
             usage: "Font",
             licenseName: "SIL Open Font License 1.1",
             url: URL(string: "https://github.com/Dicotype/Funnel")!,
             licenseFile: "LICENSE-funnel-sans"),
        Self(name: "Roboto",
             usage: "Font",
             licenseName: "SIL Open Font License 1.1",
             url: URL(string: "https://github.com/googlefonts/roboto-classic")!,
             licenseFile: "LICENSE-roboto"),
        Self(name: "Rubik",
             usage: "Font",
             licenseName: "SIL Open Font License 1.1",
             url: URL(string: "https://github.com/googlefonts/rubik")!,
             licenseFile: "LICENSE-rubik"),
    ]
    // swiftlint:enable force_unwrapping
}

/// Settings → About → Acknowledgements: each Bible translation's copyright
/// notice (from the server, the same text as the translation badge's sheet)
/// and the license of every bundled third-party component.
struct AcknowledgementsView: View {
    @Environment(BibleStore.self) private var bibleStore

    var body: some View {
        List {
            translationsSection
            openSourceSection
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await bibleStore.loadTranslations()
        }
    }

    private var translationsSection: some View {
        Section {
            if let translations = bibleStore.availableTranslations, !translations.isEmpty {
                ForEach(translations) { translation in
                    NavigationLink {
                        CopyrightSheetView(translation: translation)
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        row(title: translation.name, subtitle: translation.abbreviation)
                    }
                }
            } else if bibleStore.translationsState == .loading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Translations couldn't be loaded. Connect to the internet to see their copyright notices.")
                    .font(.app(.footnote))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("BIBLE TRANSLATIONS")
                .font(Font.app(.footnote, weight: .semibold))
        } footer: {
            Text("Scripture text is used by permission of each translation's copyright holder.")
                .font(.app(.caption2))
        }
    }

    private var openSourceSection: some View {
        Section {
            ForEach(Acknowledgement.all) { item in
                NavigationLink {
                    LicenseDetailView(acknowledgement: item)
                } label: {
                    row(title: item.name, subtitle: "\(item.usage) · \(item.licenseName)")
                }
            }
        } header: {
            Text("OPEN SOURCE")
                .font(Font.app(.footnote, weight: .semibold))
        }
    }

    private func row(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(title)
            Text(subtitle)
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
    }
}

/// One component's full license text, with a link to the project.
private struct LicenseDetailView: View {
    let acknowledgement: Acknowledgement

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Link(destination: acknowledgement.url) {
                    if acknowledgement.isGitHub {
                        Label {
                            // "owner/repo" reads better than a bare "github.com".
                            Text(acknowledgement.url.path().trimmingCharacters(in: ["/"]))
                        } icon: {
                            Image("github")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                    } else {
                        Label(acknowledgement.url.host() ?? acknowledgement.url.absoluteString,
                              image: "lucide.globe")
                    }
                }
                .font(.app(.subheadline, weight: .semibold))

                Text(acknowledgement.licenseText ?? acknowledgement.licenseName)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(acknowledgement.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AcknowledgementsView()
            .environment(BibleStore.shared)
            .environment(\.font, .app())
    }
}
