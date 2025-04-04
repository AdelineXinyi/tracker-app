//
//  LLMService.swift
//  tracker
//
//  Created by xinyi li on 4/2/25.
//

// tracker/Utilities/LLMService.swift
import Foundation

enum LLMError: Error {
    case invalidURL
    case invalidResponse
    case rateLimited
    case apiError(String)
}

struct LLMService {
    private let endpoint = "https://api.deepinfra.com/v1/openai/chat/completions"
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\n", with: "")
    private let apiKey: String  // Get from https://deepinfra.com/dash
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateSummary(for text: String) async throws -> String {
        let payload: [String: Any] = [
            "model": "mistralai/Mistral-7B-Instruct-v0.1",  // DeepInfra model name
            "messages": [
                ["role": "system", 
                 "content": "do summary less than 50 words for status with !simple, !warm, !supportive language with greetings.use emoji"],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3
        ]
        
        guard let url = URL(string: endpoint) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error details"
            throw LLMError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }
        
        let result = try JSONDecoder().decode(DeepInfraResponse.self, from: data)
        return result.choices.first?.message.content ?? "No response"
    }
    
    private struct DeepInfraResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }
}
