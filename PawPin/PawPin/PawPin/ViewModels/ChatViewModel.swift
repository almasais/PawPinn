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

struct ChatPreviewUI: Identifiable, Hashable {
    let id: UUID
    let chatSession: ChatManager.ChatSession
    var otherUserId: UUID
    var username: String
    var avatarURL: String?
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
                    self.chatPreviews = []
                    self.isLoading = false
                    return
                }

                let otherIds = ChatManager.shared.chats.map { chat in
                    chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id
                }

                // Fetch name AND avatar_url in one query
                var profileMap: [UUID: (name: String, avatarURL: String?)] = [:]
                if !otherIds.isEmpty {
                    struct UserProfile: Codable {
                        let id: UUID
                        let full_name: String?
                        let avatar_url: String?
                    }
                    let fetchedProfiles: [UserProfile] = (try? await SupabaseManager.shared.client
                        .from("users")
                        .select("id, full_name, avatar_url")
                        .in("id", values: otherIds.map { $0.uuidString })
                        .execute()
                        .value) ?? []

                    for profile in fetchedProfiles {
                        profileMap[profile.id] = (
                            name: profile.full_name ?? "User",
                            avatarURL: profile.avatar_url
                        )
                    }
                }

                // Fetch last messages
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

                                let text: String
                                if let msg = lastMsgs.first {
                                    if let t = msg.content { text = t }
                                    else if msg.imageUrl != nil { text = "📷 Photo" }
                                    else { text = "Tap to view messages" }
                                } else {
                                    text = "Tap to view messages"
                                }
                                return (chat.id, text)
                            }
                        }
                        for try await (chatId, text) in group {
                            lastMessageMap[chatId] = text
                        }
                    }
                }

                var previews: [ChatPreviewUI] = []
                for chat in ChatManager.shared.chats {
                    let otherId = chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id
                    let profile = profileMap[otherId]

                    previews.append(ChatPreviewUI(
                        id: chat.id,
                        chatSession: chat,
                        otherUserId: otherId,
                        username: profile?.name ?? "User \(String(otherId.uuidString.prefix(4)))",
                        avatarURL: profile?.avatarURL,
                        lastMessage: lastMessageMap[chat.id] ?? "Tap to view messages",
                        timeAgo: timeAgoString(from: chat.updatedAt),
                        isUnread: false
                    ))
                }

                self.chatPreviews = previews
                self.isLoading = false

            } catch {
                self.isLoading = false
                print("Error loading chats: \(error)")
            }
        }
    }

    func deleteChat(chatId: UUID) async {
        do {
            try await SupabaseManager.shared.client
                .from("messages").delete().eq("chat_id", value: chatId.uuidString).execute()
            try await SupabaseManager.shared.client
                .from("chats").delete().eq("id", value: chatId.uuidString).execute()
            self.chatPreviews.removeAll { $0.id == chatId }
        } catch {
            print("Error deleting chat: \(error)")
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
