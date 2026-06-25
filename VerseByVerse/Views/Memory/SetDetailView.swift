//
//  SetDetailView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 6/19/26.
//

import SwiftUI

struct SetDetailView: View {
    let set: StudySet

    @Environment(StudySetStore.self) private var studySetStore
    @Environment(PassageStore.self) private var passageStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentSet: StudySet
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddPassages = false

    private let jitter: Float = 0.25

    init(set: StudySet) {
        self.set = set
        _currentSet = State(initialValue: set)
    }

    /// The set's passages, resolved live from `PassageStore` via the membership in `StudySetStore`.
    private var passages: [UserPassage] {
        (studySetStore.setPassageIds[currentSet.id] ?? []).compactMap { passageStore.passagesById[$0] }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SetMesh(colorPallette: currentSet.meshTheme.palette,
                        colorShuffleSeed: currentSet.meshColorSeed,
                        positionSeed: currentSet.meshPositionSeed)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .glassEffect(in: RoundedRectangle(cornerRadius: 25))
                    .padding(.horizontal, 100)

                Text(currentSet.name)
                    .font(.app(.title3, weight: .semibold))
                HStack {
                    Text(currentSet.description ?? " ")
                        .font(.app(.callout))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                if !passages.isEmpty {
                    HStack {
                        Text("Passages")
                            .font(.app(.headline, weight: .semibold))
                        Spacer()
                        Text("\(passages.count)")
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    ForEach(passages) { passage in
                        NavigationLink(destination: PassageDetailView(passage: passage)) {
                            PassageCard(passage: passage, style: .compact)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
        .scrollIndicators(.hidden)
        .task { await refresh(lookInCache: true) }
        .refreshable { await refresh(lookInCache: false) }
        .background(SetMesh(colorPallette: currentSet.meshTheme.palette,
                            colorShuffleSeed: currentSet.meshColorSeed,
                            positionSeed: currentSet.meshPositionSeed).opacity(0.5).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Set", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            ToolbarItem {
                Button {
                    showingAddPassages = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPassages) {
            AddPassagesToSetView(setId: currentSet.id)
        }
        .sheet(isPresented: $showingEditSheet) {
            StudySetFormView(
                title: "Edit Set",
                initialName: currentSet.name,
                initialDescription: currentSet.description ?? "",
                initialTheme: currentSet.meshTheme,
                positionSeed: currentSet.meshPositionSeed,
                colorSeed: currentSet.meshColorSeed,
                confirmSystemImage: "checkmark",
                confirmTint: .blue,
            ) { name, description, theme in
                let updated = try await studySetStore.updateSet(
                    id: currentSet.id,
                    name: name,
                    description: description,
                    theme: theme,
                )
                currentSet = updated
            }
        }
        .confirmationDialog(
            "Delete \"\(currentSet.name)\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible,
        ) {
            Button("Delete", role: .destructive) {
                Task { await deleteSet() }
            }
        } message: {
            Text("This set will be permanently deleted.")
        }
    }

    /// Ensures the passage objects are loaded in `PassageStore`, then refreshes this set's membership.
    private func refresh(lookInCache: Bool) async {
        await passageStore.loadMyPassages(lookInCache: lookInCache)
        try? await studySetStore.loadPassageIds(forSet: currentSet.id)
    }

    private func deleteSet() async {
        do {
            try await studySetStore.deleteSet(id: currentSet.id)
            dismiss()
        } catch {
            // error stored in studySetStore.lastError
        }
    }
}

// MARK: - Preview

#Preview("SetDetailView") {
    let set = StudySet(
        id: 1,
        userId: "preview",
        name: "Sermon on the Mount",
        description: "Matthew 5-7, the core teachings of Jesus.",
        meshPositionSeed: 1024,
        meshColorSeed: 4096,
        meshTheme: .ocean,
        createdAt: .now.addingTimeInterval(-86400 * 14),
        modifiedAt: .now.addingTimeInterval(-3600),
    )

    let passages: [UserPassage] = [
        UserPassage(
            id: 1, userId: "preview", book: "Matthew",
            startChapter: 5, endChapter: 5, startVerse: 3, endVerse: 12,
            translation: "ESV",
            lastPracticed: .now.addingTimeInterval(-86400 * 2),
            nextPractice: .now.addingTimeInterval(86400),
            stability: 4.0, difficulty: 5.0, state: 2, reps: 5,
            lapses: 0, scheduledDays: 3, elapsedDays: 2,
        ),
        UserPassage(
            id: 2, userId: "preview", book: "Matthew",
            startChapter: 5, endChapter: 5, startVerse: 13, endVerse: 16,
            translation: "ESV",
            lastPracticed: .now.addingTimeInterval(-86400),
            nextPractice: .now,
            stability: 2.0, difficulty: 5.5, state: 2, reps: 2,
            lapses: 1, scheduledDays: 1, elapsedDays: 1,
        ),
        UserPassage(
            id: 3, userId: "preview", book: "Matthew",
            startChapter: 6, endChapter: 6, startVerse: 9, endVerse: 13,
            translation: "ESV",
            lastPracticed: nil, nextPractice: nil,
            stability: 1.0, difficulty: 5.0, state: 0, reps: 0,
            lapses: 0, scheduledDays: 0, elapsedDays: 0,
        ),
        UserPassage(
            id: 4, userId: "preview", book: "Matthew",
            startChapter: 6, endChapter: 6, startVerse: 19, endVerse: 24,
            translation: "ESV",
            lastPracticed: .now.addingTimeInterval(-86400 * 5),
            nextPractice: .now.addingTimeInterval(-86400),
            stability: 3.0, difficulty: 5.2, state: 2, reps: 3,
            lapses: 0, scheduledDays: 4, elapsedDays: 5,
        ),
        UserPassage(
            id: 5, userId: "preview", book: "Matthew",
            startChapter: 7, endChapter: 7, startVerse: 7, endVerse: 11,
            translation: "ESV",
            lastPracticed: .now.addingTimeInterval(-86400 * 3),
            nextPractice: .now.addingTimeInterval(86400 * 4),
            stability: 6.0, difficulty: 4.8, state: 2, reps: 8,
            lapses: 0, scheduledDays: 7, elapsedDays: 3,
        ),
    ]

    let passageStore = PassageStore.shared
    let studySetStore = StudySetStore.shared
    #if DEBUG
        passageStore.setUserPassagesForPreview(passages)
        studySetStore.setSetsForPreview([set])
        studySetStore.setPassageIdsForPreview([set.id: passages.map(\.id)])
    #endif

    return NavigationStack {
        SetDetailView(set: set)
    }
    .environment(\.font, .app())
    .environment(studySetStore)
    .environment(passageStore)
    .environment(BibleStore.shared)
}
