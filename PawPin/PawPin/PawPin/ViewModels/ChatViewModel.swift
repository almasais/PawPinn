//
//  ChatViewModel.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//

import Foundation
import UIKit
import Combine
import PostgREST
import Supabase

// Helper structs for UI representation
struct ChatPreviewUI: Identifiable, Hashable {
    let id: UUID
    let chatSession: ChatManager.ChatSession
    var otherUserId: UUID
    var username: String
    var userImage: String?
    var lastMessage: String
    var timeAgo: String
    var isUnread: Bool
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var chatPreviews: [ChatPreviewUI] = []
    @Published var isLoading = false
    
    func loadChats() {
        isLoading = true
        Task {
            do {
                try await ChatManager.shared.fetchChats()
                
                guard let currentUserId = AuthManager.shared.currentUserID else {
                    await MainActor.run {
                        self.chatPreviews = []
                        self.isLoading = false
                    }
                    return
                }
                
                var previews: [ChatPreviewUI] = []
                
                // Fetch profiles of other users in batch
                let otherIds = ChatManager.shared.chats.map { chat in
                    chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id
                }
                
                var profileMap: [UUID: String] = [:]
                if !otherIds.isEmpty {
                    struct UserProfile: Codable {
                        let id: UUID
                        let full_name: String?
                    }
                    let fetchedProfiles: [UserProfile] = (try? await SupabaseManager.shared.client
                        .from("users")
                        .select("id, full_name")
                        .in("id", values: otherIds.map { $0.uuidString })
                        .execute()
                        .value) ?? []
                    
                    for profile in fetchedProfiles {
                        profileMap[profile.id] = profile.full_name
                    }
                }
                
                var lastMessageMap: [UUID: String] = [:]
                if !ChatManager.shared.chats.isEmpty {
                    try await withThrowingTaskGroup(of: (UUID, String).self) { group in
                        for chat in ChatManager.shared.chats {
                            group.addTask {
                                let lastMsgs: [ChatManager.ChatMessageModel] = (try? await SupabaseManager.shared.client
                                    .from("messages")
                                    .select()
                                    .eq("chat_id", value: chat.id.uuidString)
                                    .order("created_at", ascending: false)
                                    .limit(1)
                                    .execute()
                                    .value) ?? []
                                
                                let lastMsgText: String
                                if let firstMsg = lastMsgs.first {
                                    if let text = firstMsg.content {
                                        lastMsgText = text
                                    } else if firstMsg.imageUrl != nil {
                                        lastMsgText = "📷 Photo"
                                    } else {
                                        lastMsgText = "Tap to view messages"
                                    }
                                } else {
                                    lastMsgText = "Tap to view messages"
                                }
                                return (chat.id, lastMsgText)
                            }
                        }
                        
                        for try await (chatId, text) in group {
                            lastMessageMap[chatId] = text
                        }
                    }
                }
                
                for chat in ChatManager.shared.chats {
                    let otherId = chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id
                    let username = profileMap[otherId] ?? "User \(String(otherId.uuidString.prefix(4)))"
                    let lastMsgText = lastMessageMap[chat.id] ?? "Tap to view messages"
                    
                    let preview = ChatPreviewUI(
                        id: chat.id,
                        chatSession: chat,
                        otherUserId: otherId,
                        username: username,
                        userImage: nil,
                        lastMessage: lastMsgText,
                        timeAgo: self.timeAgoString(from: chat.updatedAt),
                        isUnread: false
                    )
                    previews.append(preview)
                }
                
                await MainActor.run {
                    self.chatPreviews = previews
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error loading chats: \(error)")
                }
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
