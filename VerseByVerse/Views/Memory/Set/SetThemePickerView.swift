//
//  SetThemePickerView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 8/7/26.
//

import SwiftUI

/// Full-screen grid for choosing a `MeshTheme`, pushed from `AddSetView` so the
/// create/edit form itself stays short as the theme catalog grows.
struct SetThemePickerView: View {
    @Binding var selectedTheme: MeshTheme
    let positionSeed: Int
    let colorSeed: Int

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 84, maximum: 110), spacing: AppSpacing.md)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                ForEach(MeshTheme.allCases) { theme in
                    Button {
                        withAnimation(.snappy) { selectedTheme = theme }
                        dismiss()
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            SetMesh(
                                colorPallette: theme.palette,
                                colorShuffleSeed: colorSeed,
                                positionSeed: positionSeed,
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .stroke(
                                        selectedTheme == theme ? Color.appAccent : Color.clear,
                                        lineWidth: 3,
                                    )
                            }

                            Text(theme.displayName)
                                .font(.app(.caption, weight: selectedTheme == theme ? .semibold : .regular))
                                .foregroundStyle(selectedTheme == theme ? Color.appAccent : .secondary)
                                .lineLimit(1)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var theme: MeshTheme = .ocean
    NavigationStack {
        SetThemePickerView(selectedTheme: $theme, positionSeed: 42, colorSeed: 7)
    }
    .environment(\.font, .app())
}
