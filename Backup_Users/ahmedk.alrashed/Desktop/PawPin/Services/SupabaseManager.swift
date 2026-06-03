//
//  SupabaseManager.swift
//  PawPin
//

import Foundation
import Supabase
import UIKit

class SupabaseManager {
    static let shared = SupabaseManager()
    
    // Your Supabase credentials
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://nzuxlorkzeiikjwxiezv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56dXhsb3JremVpaWtqd3hpZXp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODU4MjAsImV4cCI6MjA5NDc2MTgyMH0._jepdWnjN7d1Y8au76xDcJsPpMcc9V1tLmLUUvKgfDY"
    )
    
    // ─────────────────────────────
    // UPLOAD PHOTO
    // ─────────────────────────────
    func uploadPhotoAsync(photo: UIImage, reportID: String) async throws -> String {
        guard let imageData = photo.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }
        
        try await client.storage
            .from("cat-photos")
            .upload(
                path: "\(reportID).jpg",
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        let url = try client.storage
            .from("cat-photos")
            .getPublicURL(path: "\(reportID).jpg")
        
        return url.absoluteString
    }
    
    // ─────────────────────────────
    // SAVE REPORT
    // ─────────────────────────────
    func saveReportAsync(report: CatReport, photo: UIImage?) async throws {
        var photoURL = report.photoURL
        
        if let photo = photo {
            photoURL = try await uploadPhotoAsync(photo: photo, reportID: report.id)
        }
        
        let data = ReportRow(
            id: report.id,
            report_type: report.reportType,
            owner_name: report.ownerName,
            contact_info: report.contactInfo,
            photo_url: photoURL,
            breed: report.features.breed,
            fur_colors: report.features.furColors.joined(separator: ","),
            eye_color: report.features.eyeColor,
            pattern: report.features.pattern,
            ear_type: report.features.earType,
            size: report.features.size,
            date: ISO8601DateFormatter().string(from: report.date),
            user_id: report.userId
        )
        
        try await client
            .from("reports")
            .insert(data)
            .execute()
    }
    
    // ─────────────────────────────
    // GET REPORTS
    // ─────────────────────────────
    func getAllReportsAsync() async throws -> [CatReport] {
        let response: [ReportRow] = try await client
            .from("reports")
            .select()
            .execute()
            .value
        
        return response.map { rowToCatReport($0) }
    }
    
    func getLostReportsAsync() async throws -> [CatReport] {
        let response: [ReportRow] = try await client
            .from("reports")
            .select()
            .eq("report_type", value: "lost")
            .execute()
            .value
        
        return response.map { rowToCatReport($0) }
    }
    
    func getUserReportsAsync(userId: UUID) async throws -> [CatReport] {
        let response: [ReportRow] = try await client
            .from("reports")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return response.map { rowToCatReport($0) }
    }
    
    // ─────────────────────────────
    // DELETE REPORT
    // ─────────────────────────────
    func deleteReportAsync(reportID: String) async throws {
        try await client
            .from("reports")
            .delete()
            .eq("id", value: reportID)
            .execute()
    }
    
    func markReportAsFoundAsync(reportID: String) async throws {
        struct UpdateReport: Codable {
            let report_type: String
        }
        try await client
            .from("reports")
            .update(UpdateReport(report_type: "found"))
            .eq("id", value: reportID)
            .execute()
    }
    
    // ─────────────────────────────
    // CONVERT ROW TO CatReport
    // ─────────────────────────────
    private func rowToCatReport(_ row: ReportRow) -> CatReport {
        let furColors = row.fur_colors
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let features = CatFeatures(
            breed: row.breed,
            furColors: furColors,
            eyeColor: row.eye_color,
            pattern: row.pattern,
            earType: row.ear_type,
            size: row.size
        )
        
        let date = ISO8601DateFormatter().date(from: row.date) ?? Date()
        
        return CatReport(
            id: row.id,
            reportType: row.report_type,
            ownerName: row.owner_name,
            contactInfo: row.contact_info,
            photoURL: row.photo_url,
            features: features,
            date: date,
            userId: row.user_id
        )
    }
    
    // Legacy callbacks for compatibility until all are replaced
    func saveReport(report: CatReport, photo: UIImage, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await saveReportAsync(report: report, photo: photo)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    
    func getLostReports(completion: @escaping ([CatReport]) -> Void) {
        Task {
            do {
                let reports = try await getLostReportsAsync()
                completion(reports)
            } catch {
                completion([])
            }
        }
    }
    
    func getAllReports(completion: @escaping ([CatReport]) -> Void) {
        Task {
            do {
                let reports = try await getAllReportsAsync()
                completion(reports)
            } catch {
                completion([])
            }
        }
    }
}

struct ReportRow: Codable {
    let id: String
    let report_type: String
    let owner_name: String
    let contact_info: String
    let photo_url: String?
    let breed: String
    let fur_colors: String
    let eye_color: String
    let pattern: String
    let ear_type: String
    let size: String
    let date: String
    let user_id: UUID?
}

