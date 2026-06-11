//
//  SupabaseManager.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//

import Foundation
import Supabase
import UIKit

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://nzuxlorkzeiikjwxiezv.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56dXhsb3JremVpaWtqd3hpZXp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODU4MjAsImV4cCI6MjA5NDc2MTgyMH0._jepdWnjN7d1Y8au76xDcJsPpMcc9V1tLmLUUvKgfDY"
    )
    
    // ─────────────────────────────
    // UPLOAD PHOTO
    // ─────────────────────────────
    func uploadPhotoAsync(photo: UIImage, reportID: String) async throws -> String {
        let resizedPhoto = photo.resized(toMaxDimension: 1200)
        guard let imageData = resizedPhoto.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }
        
        try await client.storage
            .from("cat-photos")
            .upload(
                "\(reportID).jpg",
                data: imageData,
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
    func saveReportAsync(report: CatReport, photo: UIImage?, latitude: Double?, longitude: Double?, description: String?, rewardAmount: Double?, locationName: String?, petName: String?) async throws {
        var photoURL = report.photoURL
        
        if let photo = photo {
            photoURL = try await uploadPhotoAsync(photo: photo, reportID: report.id)
        }
        
        let data = InsertReportRow(
            id: UUID(uuidString: report.id) ?? UUID(),
            report_type: report.reportType,
            photo_url: photoURL,
            breed: report.features.breed,
            fur_colors: report.features.furColors.joined(separator: ","),
            eye_color: report.features.eyeColor,
            pattern: report.features.pattern,
            ear_type: report.features.earType,
            size: report.features.size,
            user_id: report.userId,
            latitude: latitude,
            longitude: longitude,
            description: description,
            reward_amount: rewardAmount,
            location_name: locationName,
            pet_name: petName
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
        let response: [ReportRowWithUser] = try await client
            .from("reports")
            .select("*, users(full_name)")
            .execute()
            .value
        
        return response.map { rowToCatReport($0) }
    }
    
    func getLostReportsAsync() async throws -> [CatReport] {
        let response: [ReportRowWithUser] = try await client
            .from("reports")
            .select("*, users(full_name)")
            .eq("report_type", value: "lost")
            .execute()
            .value
        
        return response.map { rowToCatReport($0) }
    }
    
    func getUserReportsAsync(userId: UUID) async throws -> [CatReport] {
        let response: [ReportRowWithUser] = try await client
            .from("reports")
            .select("*, users(full_name)")
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
    private func rowToCatReport(_ row: ReportRowWithUser) -> CatReport {
        let furColors = (row.fur_colors ?? "")
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let features = CatFeatures(
            breed: row.breed ?? "",
            furColors: furColors,
            eyeColor: row.eye_color ?? "",
            pattern: row.pattern ?? "",
            earType: row.ear_type ?? "",
            size: row.size ?? ""
        )
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: row.created_at) ?? Date()
        
        return CatReport(
            id: row.id.uuidString,
            reportType: row.report_type,
            ownerName: row.users?.full_name ?? "Anonymous",
            petName: row.pet_name,
            contactInfo: "in-app chat",
            photoURL: row.photo_url,
            features: features,
            date: date,
            userId: row.user_id,
            latitude: row.latitude,
            longitude: row.longitude,
            description: row.description,
            locationName: row.location_name,
            rewardAmount: row.reward_amount
        )
    }
    
    // Legacy callbacks
    func saveReport(report: CatReport, photo: UIImage, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await saveReportAsync(
                    report: report,
                    photo: photo,
                    latitude: report.latitude,
                    longitude: report.longitude,
                    description: report.description,
                    rewardAmount: report.rewardAmount,
                    locationName: report.locationName,
                    petName: report.petName
                )
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

// ─────────────────────────────
// Database structures
// ─────────────────────────────
struct InsertReportRow: Codable {
    let id: UUID
    let report_type: String
    let photo_url: String?
    let breed: String
    let fur_colors: String
    let eye_color: String
    let pattern: String
    let ear_type: String
    let size: String
    let user_id: UUID?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let reward_amount: Double?
    let location_name: String?
    let pet_name: String?
}

struct ReportRowWithUser: Codable {
    let id: UUID
    let created_at: String
    let report_type: String
    let photo_url: String?
    let breed: String?
    let fur_colors: String?
    let eye_color: String?
    let pattern: String?
    let ear_type: String?
    let size: String?
    let user_id: UUID?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let reward_amount: Double?
    let location_name: String?
    let pet_name: String?
    let users: UserProfileJoin?
    
    struct UserProfileJoin: Codable {
        let full_name: String?
    }
}
