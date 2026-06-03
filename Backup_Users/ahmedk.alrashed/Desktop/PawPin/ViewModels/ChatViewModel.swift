//
//  ChatViewModel.swift
//  PawPin
//

import Foundation
import UIKit
import Combine

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
                
                guard let currentUserId = AuthManager.shared.currentUserID else { return }
                
                var previews: [ChatPreviewUI] = []
                for chat in ChatManager.shared.chats {
                    let otherId = chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id
                    
                    // In a real app, fetch the other user's profile info here.
                    // For now, use placeholders.
                    
                    let preview = ChatPreviewUI(
                        id: chat.id,
                        chatSession: chat,
                        otherUserId: otherId,
                        username: "User \(String(otherId.uuidString.prefix(4)))",
                        userImage: nil,
                        lastMessage: "Tap to view messages",
                        timeAgo: timeAgoString(from: chat.updatedAt),
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
