//
//  MessageView.swift
//  PawPin
//

import SwiftUI
import PhotosUI

struct MessageView: View {
    let chatPreview: ChatPreviewUI
    
    @StateObject private var chatManager = ChatManager.shared
    @State private var newMessage = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    
    private var currentUserId: UUID? {
        AuthManager.shared.currentUserID
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(chatManager.currentMessages) { msg in
                            let isCurrentUser = msg.senderId == currentUserId
                            HStack {
                                if isCurrentUser { Spacer() }

                                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 3) {
                                    if let imageUrlStr = msg.imageUrl, let url = URL(string: imageUrlStr) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFit().frame(maxWidth: 220).cornerRadius(16)
                                        } placeholder: {
                                            Color(.systemGray5).frame(width: 220, height: 150).cornerRadius(16)
                                        }
                                    } else if let text = msg.content {
                                        Text(text)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                isCurrentUser
                                                    ? Color.brand.opacity(0.85)
                                                    : Color(.systemGray5)
                                            )
                                            .cornerRadius(18)
                                            .foregroundColor(isCurrentUser ? .white : .primary)
                                    }

                                    HStack(spacing: 4) {
                                        Text(msg.createdAt, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.gray)

                                        if isCurrentUser {
                                            Image(systemName: msg.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                                                .font(.caption2)
                                                .foregroundColor(msg.isRead ? Color.brand : .gray)
                                        }
                                    }
                                }

                                if !isCurrentUser { Spacer() }
                            }
                            .padding(.horizontal)
                            .id(msg.id)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: chatManager.currentMessages.count) { _ in
                    if let last = chatManager.currentMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color.brand)
                }

                TextField("Message", text: $newMessage)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                Button {
                    guard !newMessage.isEmpty else { return }
                    let textToSend = newMessage
                    newMessage = ""
                    Task {
                        try? await chatManager.sendMessage(chatId: chatPreview.id, content: textToSend, imageUrl: nil)
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color.brand)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    if let img = chatPreview.userImage {
                        Image(img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 34, height: 34)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                    }
                    Text(chatPreview.username)
                        .font(.headline)
                }
            }
        }
        .onAppear {
            Task {
                try? await chatManager.fetchMessages(for: chatPreview.id)
                await chatManager.startRealtimeSubscription(for: chatPreview.id)
            }
        }
        .onDisappear {
            chatManager.stopRealtimeSubscription()
            chatManager.currentMessages = []
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    do {
                        let photoUrl = try await SupabaseManager.shared.uploadPhotoAsync(
                            photo: uiImage,
                            reportID: UUID().uuidString
                        )
                        try await chatManager.sendMessage(
                            chatId: chatPreview.id,
                            content: nil,
                            imageUrl: photoUrl
                        )
                    } catch {
                        print("Error uploading/sending chat image: \(error)")
                    }
                }
            }
        }
    }
}
