//
//  NumericRefTextField.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import SwiftUI

struct NumericRefTextField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    @FocusState.Binding var focus: AddPassageView.Field?
    let thisField: AddPassageView.Field
    let submitLabel: SubmitLabel
    let width: CGFloat
    let onSubmitAction: () -> Void
    let onChangeAction: (String) -> Void

    init(placeholder: String,
         text: Binding<String>,
         isFocused: Bool,
         focus: FocusState<AddPassageView.Field?>.Binding,
         thisField: AddPassageView.Field,
         submitLabel: SubmitLabel,
         width: CGFloat,
         onSubmit: @escaping () -> Void,
         onChange: @escaping (String) -> Void)
    {
        self.placeholder = placeholder
        _text = text
        self.isFocused = isFocused
        _focus = focus
        self.thisField = thisField
        self.submitLabel = submitLabel
        self.width = width
        onSubmitAction = onSubmit
        onChangeAction = onChange
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .textFieldStyle(.plain)
            .frame(width: width)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(.secondarySystemBackground)),
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isFocused ? Color.appAccent.opacity(0.8) : Color.secondary.opacity(0.2), lineWidth: 1.5),
            )
            .multilineTextAlignment(.center)
            .focused($focus, equals: thisField)
            .submitLabel(submitLabel)
            .onSubmit { onSubmitAction() }
            .onChange(of: text) { _, newValue in
                onChangeAction(newValue)
            }
    }
}
