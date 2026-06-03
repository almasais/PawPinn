//
//  GeminiService.swift
//  PawPin
//

import Foundation
import UIKit

class GeminiService {
    
    // Your API key
    private let apiKey = "AIzaSyApjN0N0bwMVTAtyty0HttryKH4mQOknUs"
    private let apiURL = "https://aistudio.google.com/api-keys?project=gen-lang-client-0331437392"
    
    struct GeminiJSONResponse: Codable {
        let breed: String
        let fur_colors: [String]
        let eye_color: String
        let pattern: String
        let ear_type: String
        let size: String
    }
    
    func analyzeCatPhotoAsync(photo: UIImage) async throws -> CatFeatures? {
        guard let imageData = photo.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Analyze this cat photo and return a structured JSON response.
        Extract the following:
        - "breed": breed name (e.g., Persian, Siamese, Arabian Mau, or "Unknown")
        - "fur_colors": array of colors (e.g., ["white", "black"])
        - "eye_color": color (e.g., "green", "blue", "yellow")
        - "pattern": fur pattern (e.g., "solid", "tabby", "calico", "bicolor")
        - "ear_type": ear type (e.g., "pointed", "folded")
        - "size": apparent size (e.g., "small", "medium", "large")
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"),
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Gemini API Error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            return nil
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return nil
        }
        
        guard let textData = text.data(using: .utf8) else { return nil }
        let parsed = try JSONDecoder().decode(GeminiJSONResponse.self, from: textData)
        
        return CatFeatures(
            breed: parsed.breed,
            furColors: parsed.fur_colors,
            eyeColor: parsed.eye_color,
            pattern: parsed.pattern,
            earType: parsed.ear_type,
            size: parsed.size
        )
    }
}
