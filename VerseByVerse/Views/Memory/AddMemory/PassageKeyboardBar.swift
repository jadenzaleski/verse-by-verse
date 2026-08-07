//
//  PassageKeyboardBar.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/4/26.
//

import SwiftUI

struct PassageKeyboardBar: View {
    let namespace: Namespace.ID
    let limits: (min: Int, max: Int)
    let isRefValid: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSetValue: (Int) -> Void
    let onDone: () -> Void

    var body: some View {
        HStack {
            GlassEffectContainer {
                HStack {
                    Button {
                        onPrevious()
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 20, height: 20)
                            .padding()
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 1, namespace: namespace)
                    }

                    Button {
                        onNext()
                    } label: {
                        Image(systemName: "chevron.left")
                            .rotationEffect(.degrees(180))
                            .frame(width: 20, height: 20)
                            .padding()
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 1, namespace: namespace)
                    }
                }
            }

            Spacer()

            GlassEffectContainer {
                HStack {
                    Button {
                        onSetValue(limits.min)
                    } label: {
                        Text("\(limits.min)")
                            .padding()
                            .padding(.leading, AppSpacing.md)
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 2, namespace: namespace)
                    }

                    Divider()
                        .frame(width: 1, height: 20)
                        .overlay(.separator)
                        .glassEffect()
                        .glassEffectUnion(id: 2, namespace: namespace)

                    Button {
                        onSetValue(limits.max)
                    } label: {
                        Text("\(limits.max)")
                            .padding()
                            .padding(.trailing, AppSpacing.md)
                            .glassEffect(.regular.interactive())
                            .glassEffectUnion(id: 2, namespace: namespace)
                    }
                }
            }

            Button {
                withAnimation {
                    onDone()
                }
            } label: {
                Image(systemName: "checkmark")
                    .foregroundStyle(.windowBackground)
                    .frame(width: 20, height: 20)
                    .padding()
                    .glassEffect(.regular.tint(isRefValid ? .green : Color(.systemGray4)).interactive())
            }
            .disabled(!isRefValid)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
