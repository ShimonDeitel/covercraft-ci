import Foundation

enum Tone: String, CaseIterable, Identifiable {
    case professional   = "Professional"
    case enthusiastic   = "Enthusiastic"
    case concise        = "Concise"
    var id: String { rawValue }
}

enum OpenRouterError: Error, LocalizedError {
    case badStatus(Int)
    case noContent
    case network(Error)
    var errorDescription: String? {
        switch self {
        case .badStatus(let c): return "Server returned \(c). Check your API key."
        case .noContent: return "The AI returned an empty response. Try again."
        case .network(let e): return e.localizedDescription
        }
    }
}

struct OpenRouterService {
    // Replace with your real OpenRouter key.
    static let apiKey = "sk-or-placeholder"
    static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    static func generate(jobTitle: String, company: String, standout: String, tone: Tone) async throws -> String {
        let toneInstruction: String
        switch tone {
        case .professional:  toneInstruction = "Use a professional, polished tone."
        case .enthusiastic:  toneInstruction = "Use an enthusiastic, energetic tone that shows genuine excitement."
        case .concise:       toneInstruction = "Be concise — 3 short paragraphs, no filler words."
        }

        let system = """
You are an expert cover letter writer. Write a compelling, tailored cover letter in exactly 3 paragraphs.
Do NOT include a greeting line, date, or sign-off — only the 3 body paragraphs.
\(toneInstruction)
"""
        let user = """
Job title: \(jobTitle)
Company: \(company)
What makes this candidate stand out: \(standout)
"""

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("CoverCraft iOS App", forHTTPHeaderField: "HTTP-Referer")

        let body: [String: Any] = [
            "model": "openai/gpt-4o-mini",
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ],
            "max_tokens": 600,
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OpenRouterError.network(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw OpenRouterError.badStatus(http.statusCode)
        }

        struct Choice: Decodable {
            struct Message: Decodable { let content: String? }
            let message: Message
        }
        struct Resp: Decodable { let choices: [Choice] }

        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let text = decoded.choices.first?.message.content, !text.isEmpty else {
            throw OpenRouterError.noContent
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
