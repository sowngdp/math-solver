//
//  MathSolver.swift
//  math-solver
//
//  Created by SownFrenky on 9/13/25.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public struct ChatMessage: Identifiable, Equatable, Sendable {
    public enum Role: String, Sendable {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date

    public init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = .now) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

actor MathSolver {
#if canImport(FoundationModels)
    private var model: SystemLanguageModel?
    private var session: LanguageModelSession?
#endif

    init() {
        // Lazy init for the model/session to avoid hard dependency when the framework isn't present
    }

    func solve(problem: String, history: [ChatMessage]) async -> String {
        // Prefer on-device/inbox Foundation model when available
#if canImport(FoundationModels)
        do {
            if model == nil {
                // Choose a general reasoning-capable model. Fallback to system default if specific model isn't available.
                model = try SystemLanguageModel.default
            }

            if session == nil, let model {
                session = try await model.startSession(systemPrompt: \
"You are a meticulous math solver. Solve the user's math problem step by step. Show reasoning succinctly and provide the final answer clearly.")
            }

            if let session {
                var messages: [LanguageModelMessage] = []
                for msg in history {
                    switch msg.role {
                    case .user:
                        messages.append(.user(msg.content))
                    case .assistant:
                        messages.append(.assistant(msg.content))
                    }
                }
                messages.append(.user(problem))

                let response = try await session.generate(messages: messages)
                return response.text
            }
        } catch {
            // Fall through to heuristic solver
        }
#endif

        // Heuristic fallback: try to evaluate simple arithmetic using NSExpression
        if let value = Self.evaluateArithmetic(problem) {
            return "Kết quả: \(value)"
        }
        return "Xin lỗi, mình chưa thể giải bài này. Hãy viết lại ngắn gọn hoặc rõ ràng hơn."
    }

    private static func evaluateArithmetic(_ input: String) -> Double? {
        // Extract a simple math expression from the input
        let allowed = CharacterSet(charactersIn: "0123456789+-*/()., ")
        let filtered = String(input.unicodeScalars.filter { allowed.contains($0) })
            .replacingOccurrences(of: ",", with: ".")
        guard !filtered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let expression = NSExpression(format: filtered)
        if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.doubleValue
        }
        return nil
    }
}
