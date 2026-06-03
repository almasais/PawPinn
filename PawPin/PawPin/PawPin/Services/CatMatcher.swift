//
//  CatMatcher.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//

import UIKit

class CatMatcher {
    
    let gemini = GeminiService()
    
    func findMatchesAsync(photo: UIImage, allReports: [CatReport]) async throws -> [CatMatch] {
        guard let foundFeatures = try await gemini.analyzeCatPhotoAsync(photo: photo) else {
            return []
        }
        
        var matches: [CatMatch] = []
        
        for report in allReports {
            let score = calculateScore(found: foundFeatures, report: report.features)
            
            if score >= 50 {
                matches.append(CatMatch(report: report, score: score))
            }
        }
        
        return matches.sorted { $0.score > $1.score }
    }
    
    // Calculate similarity score (case-insensitive)
    private func calculateScore(found: CatFeatures, report: CatFeatures) -> Int {
        var score = 0
        
        // Breed match (most important)
        if found.breed.lowercased() == report.breed.lowercased() {
            score += 40
        }
        
        // Fur colors match
        let foundColors = Set(found.furColors.map { $0.lowercased() })
        let reportColors = Set(report.furColors.map { $0.lowercased() })
        let sharedColors = foundColors.intersection(reportColors)
        score += sharedColors.count * 10 // 10 per shared color
        
        // Eye color match
        if found.eyeColor.lowercased() == report.eyeColor.lowercased() {
            score += 20
        }
        
        // Pattern match
        if found.pattern.lowercased() == report.pattern.lowercased() {
            score += 15
        }
        
        // Ear type match
        if found.earType.lowercased() == report.earType.lowercased() {
            score += 10
        }
        
        return min(score, 100)
    }
    
    // Legacy support
    func findMatches(photo: UIImage, allReports: [CatReport], completion: @escaping ([CatMatch]) -> Void) {
        Task {
            do {
                let matches = try await findMatchesAsync(photo: photo, allReports: allReports)
                completion(matches)
            } catch {
                completion([])
            }
        }
    }
}