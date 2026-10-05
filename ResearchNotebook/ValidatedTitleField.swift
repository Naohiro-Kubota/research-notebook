import SwiftUI

struct ValidatedTitleField: View {
  @Binding var title: String
  let label: String
  let accessibilityID: String
  @State private var draft = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading) {
      TextField(label, text: $draft)
        .accessibilityIdentifier(accessibilityID)
        .focused($isFocused)
        .onAppear { draft = title }
        .onChange(of: draft) { _, value in
          if isValidTitle(value) { title = value }
        }
        .onChange(of: isFocused) { _, focused in
          if !focused { draft = title }
        }
        .onChange(of: title) { _, value in
          if !isFocused { draft = value }
        }
      if !isValidTitle(draft) {
        Text("タイトルを入力してください。空白だけのタイトルは使えません。")
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("title-validation-error")
      }
    }
  }
}
