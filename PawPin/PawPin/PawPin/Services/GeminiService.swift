//
//  GeminiService.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 02/12/1447 AH.
//

import UIKit

class GeminiService {
    
    // API key and endpoints
    private let apiKey = "AIzaSyApjN0N0bwMVTAtyty0HttryKH4mQOknUs"
    
    struct GeminiJSONResponse: Codable {
        let breed: String
        let fur_colors: [String]
        let eye_color: String
        let pattern: String
        let ear_type: String
        let size: String
    }
    
    func analyzeCatPhotoAsync(photo: UIImage) async throws -> CatFeatures? {
        let resizedPhoto = photo.resized(toMaxDimension: 800)
        guard let imageData = resizedPhoto.jpegData(compressionQuality: 0.7) else {
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
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"),
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Gemini API Error: \((response as? HTTPURLResponse)?.statusCode ?? 0) - \(errorMsg)")
            return nil
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return nil
        }
        
        func extractJSON(from text: String) -> String? {
            guard let firstOpen = text.firstIndex(of: "{"),
                  let lastClose = text.lastIndex(of: "}") else {
                return nil
            }
            return String(text[firstOpen...lastClose])
        }
        
        guard let cleanedText = extractJSON(from: text),
              let textData = cleanedText.data(using: .utf8) else {
            print("Gemini response text didn't contain valid JSON bounds: \(text)")
            return nil
        }
        
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
    
    // Legacy support
    func analyzeCatPhoto(photo: UIImage, completion: @escaping (CatFeatures?) -> Void) {
        Task {
            do {
                let features = try await analyzeCatPhotoAsync(photo: photo)
                completion(features)
            } catch {
                completion(nil)
            }
        }
    }
}

// MARK: - UIImage Resizing Extension
extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let aspectRatio = size.width / size.height
        
        var newSize = CGSize.zero
        if aspectRatio > 1 {
            newSize.width = min(size.width, maxDimension)
            newSize.height = newSize.width / aspectRatio
        } else {
            newSize.height = min(size.height, maxDimension)
            newSize.width = newSize.height * aspectRatio
        }
        
        if newSize.width >= size.width || newSize.height >= size.height {
            return self
        }
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
