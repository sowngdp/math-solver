//
//  ContentView.swift
//  math-solver
//
//  Created by SownFrenky on 9/13/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack(alignment: .top) {
                                if message.role == .assistant { Spacer(minLength: 0) }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(message.role == .user ? "Bạn" : "Trợ lý")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(message.content)
                                        .font(.body)
                                        .padding(12)
                                        .background(message.role == .user ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                if message.role == .user { Spacer(minLength: 0) }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Nhập bài toán...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button(action: send) {
                    if viewModel.isThinking {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("Giải toán")
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.send(text)
    }
}

#Preview {
    ContentView()
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isThinking: Bool = false

    private let solver = MathSolver()

    func send(_ text: String) {
        let user = ChatMessage(role: .user, content: text)
        messages.append(user)
        isThinking = true

        Task {
            let response = await solver.solve(problem: text, history: messages)
            await MainActor.run {
                self.messages.append(ChatMessage(role: .assistant, content: response))
                self.isThinking = false
            }
        }
    }
}
