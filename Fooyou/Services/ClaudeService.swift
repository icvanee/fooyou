import Foundation

// Stub — Claude API integration is Phase 1b.
// Reads API key from Secrets.xcconfig → CLAUDE_API_KEY build variable.
final class ClaudeService {
    static let shared = ClaudeService()
    private init() {}

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String ?? ""
    }

    func parseReceiptText(_ text: String) async throws -> ClaudeReceiptResponse {
        // TODO Phase 1b
        throw ClaudeError.notImplemented
    }

    func parseReceiptPDF(_ data: Data) async throws -> ClaudeReceiptResponse {
        // TODO Phase 1b
        throw ClaudeError.notImplemented
    }

    func parseRecipeText(_ text: String) async throws -> ClaudeRecipeResponse {
        // TODO Phase 1b
        throw ClaudeError.notImplemented
    }
}

enum ClaudeError: LocalizedError {
    case notImplemented
    case apiError(String)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .notImplemented: return "Nog niet geïmplementeerd."
        case .apiError(let msg): return "Claude API fout: \(msg)"
        case .missingAPIKey: return "CLAUDE_API_KEY ontbreekt in Secrets.xcconfig."
        }
    }
}
