//
//  ChatListView.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 25/11/1447 AH.
//
import SwiftUI

struct ChatListView: View {
    @StateObject private var chatVM = ChatViewModel()
    @Binding var showTabBar: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image("userProfile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.orange, lineWidth: 2))

                    Text("Messages")
                        .font(.title).bold()

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if chatVM.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if chatVM.chatPreviews.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "message", title: "No Messages", message: "When you contact a pet owner, messages will appear here.")
                    Spacer()
                } else {
                    List(chatVM.chatPreviews) { chat in
                        NavigationLink(
                            destination: MessageView(chatPreview: chat)
                                .onAppear { showTabBar = false }
                                .onDisappear { showTabBar = true }
                        ) {
                            HStack(spacing: 12) {
                                if let imagePath = chat.userImage {
                                    Image(imagePath)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 55, height: 55)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 55, height: 55)
                                        .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chat.username)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(chat.lastMessage)
                                        .font(.subheadline)
                                        .foregroundColor(chat.isUnread ? .blue : .gray)
                                }

                                Spacer()

                                VStack(spacing: 6) {
                                    Text(chat.timeAgo)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    if chat.isUnread {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 9, height: 9)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await chatVM.deleteChat(chatId: chat.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        chatVM.loadChats()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                chatVM.loadChats()
            }
        }
    }
}

