//
//  ChatManager.swift
//  PawPin
//

import Foundation
import Supabase
import Combine

@MainActor
class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var chats: [ChatSession] = []
    @Published var currentMessages: [ChatMessageModel] = []
    
    private var messagesChannel: RealtimeChannel?
    
    // Model definitions to match DB
    struct ChatSession: Codable, Identifiable, Hashable {
        let id: UUID
        let createdAt: Date
        let user1Id: UUID
        let user2Id: UUID
        let reportId: UUID?
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case createdAt = "created_at"
            case user1Id = "user1_id"
            case user2Id = "user2_id"
            case reportId = "report_id"
            case updatedAt = "updated_at"
        }
    }

    struct ChatMessageModel: Codable, Identifiable, Hashable {
        let id: UUID
        let chatId: UUID
        let senderId: UUID
        let content: String?
        let imageUrl: String?
        let createdAt: Date
        let isRead: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case chatId = "chat_id"
            case senderId = "sender_id"
            case content
            case imageUrl = "image_url"
            case createdAt = "created_at"
            case isRead = "is_read"
        }
    }
    
    private init() {}
    
    func fetchChats() async throws {
        guard let currentUserId = AuthManager.shared.currentUserID else { return }
        
        // Fetch chats where user1_id == currentUser OR user2_id == currentUser
        let fetchedChats1: [ChatSession] = try await SupabaseManager.shared.client
            .from("chats")
            .select()
            .eq("user1_id", value: currentUserId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
            
        let fetchedChats2: [ChatSession] = try await SupabaseManager.shared.client
            .from("chats")
            .select()
            .eq("user2_id", value: currentUserId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value
        
        var allChats = fetchedChats1 + fetchedChats2
        allChats.sort { $0.updatedAt > $1.updatedAt }
        
        await MainActor.run {
            self.chats = allChats
        }
    }
    
    func getOrCreateChat(otherUserId: UUID, reportId: UUID?) async throws -> ChatSession {
        guard let currentUserId = AuthManager.shared.currentUserID else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let fetched1: [ChatSession] = try await SupabaseManager.shared.client
            .from("chats")
            .select()
            .eq("user1_id", value: currentUserId.uuidString)
            .eq("user2_id", value: otherUserId.uuidString)
            .execute()
            .value
            
        if let chat = fetched1.first {
            return chat
        }
        
        let fetched2: [ChatSession] = try await SupabaseManager.shared.client
            .from("chats")
            .select()
            .eq("user1_id", value: otherUserId.uuidString)
            .eq("user2_id", value: currentUserId.uuidString)
            .execute()
            .value
            
        if let chat = fetched2.first {
            return chat
        }
        
        struct NewChat: Codable {
            let id: UUID
            let user1_id: UUID
            let user2_id: UUID
            let report_id: UUID?
        }
        
        let newChat = NewChat(
            id: UUID(),
            user1_id: currentUserId,
            user2_id: otherUserId,
            report_id: reportId
        )
        
        let inserted: [ChatSession] = try await SupabaseManager.shared.client
            .from("chats")
            .insert(newChat)
            .select()
            .execute()
            .value
            
        guard let createdChat = inserted.first else {
            throw URLError(.badServerResponse)
        }
        
        return createdChat
    }
    
    func fetchMessages(for chatId: UUID) async throws {
        let messages: [ChatMessageModel] = try await SupabaseManager.shared.client
            .from("messages")
            .select()
            .eq("chat_id", value: chatId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
            
        await MainActor.run {
            self.currentMessages = messages
        }
    }
    
    func sendMessage(chatId: UUID, content: String?, imageUrl: String?) async throws {
        guard let senderId = AuthManager.shared.currentUserID else { return }
        
        let newMessage = ChatMessageModel(
            id: UUID(),
            chatId: chatId,
            senderId: senderId,
            content: content,
            imageUrl: imageUrl,
            createdAt: Date(),
            isRead: false
        )
        
        try await SupabaseManager.shared.client
            .from("messages")
            .insert(newMessage)
            .execute()
            
        // Update the chat's updated_at
        struct UpdateChat: Codable {
            let updated_at: Date
        }
        try await SupabaseManager.shared.client
            .from("chats")
            .update(UpdateChat(updated_at: Date()))
            .eq("id", value: chatId.uuidString)
            .execute()
    }
    
    func startRealtimeSubscription(for chatId: UUID) async {
        messagesChannel?.unsubscribe()
        
        let channel = await SupabaseManager.shared.client.channel("public:messages:chat_id=eq.\(chatId.uuidString)")
        
        let stream = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "chat_id=eq.\(chatId.uuidString)"
        )
        
        await channel.subscribe()
        self.messagesChannel = channel
        
        Task {
            for await change in stream {
                do {
                    let data = try JSONSerialization.data(withJSONObject: change.record)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let newMessage = try decoder.decode(ChatMessageModel.self, from: data)
                    
                    await MainActor.run {
                        if !self.currentMessages.contains(where: { $0.id == newMessage.id }) {
                            self.currentMessages.append(newMessage)
                        }
                    }
                } catch {
                    print("Error decoding realtime message: \(error)")
                }
            }
        }
    }
    
    func stopRealtimeSubscription() {
        messagesChannel?.unsubscribe()
        messagesChannel = nil
    }
}
