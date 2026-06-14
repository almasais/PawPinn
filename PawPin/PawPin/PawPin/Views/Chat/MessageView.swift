//
//  MessageView.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 25/11/1447 AH.
//

import SwiftUI
import PhotosUI
import Supabase
import UserNotifications

struct MessageView: View {
    let chatPreview: ChatPreviewUI
    var shouldRestoreTabBarOnDisappear: Bool = true
    
    @Environment(\.showTabBar) private var showTabBar: Binding<Bool>
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var chatManager = ChatManager.shared
    @State private var newMessage = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    
    @State private var pendingImage: UIImage? = nil
    @State private var showCamera = false
    @State private var isUploading = false
    
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
                                                    : (colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray5))
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
                            .contextMenu {
                                // existing context menu could be here (not present in original code but per instruction)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await deleteMessage(id: msg.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: chatManager.currentMessages.count) { _ in
                    guard let last = chatManager.currentMessages.last else { return }
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                    let isCurrentUser = last.senderId == currentUserId
                    if !isCurrentUser {
                        scheduleLocalNotificationFor(messageId: last.id, contentText: last.content, imageUrl: last.imageUrl, from: chatPreview.username)
                    }
                }
            }

            // Attachment Preview Banner
            if let image = pendingImage {
                HStack(alignment: .bottom) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 2)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                pendingImage = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black))
                                .font(.system(size: 18))
                        }
                        .offset(x: 6, y: -6)
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 0.95, green: 0.95, blue: 0.97))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Input Bar
            HStack(spacing: 12) {
                // Camera Button
                Button {
                    showCamera = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.brand)
                }
                .disabled(isUploading)
                
                // Photo Picker Button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.brand)
                }
                .disabled(isUploading)

                // Message Text Field
                TextField(pendingImage != nil ? "Add a caption..." : "Message", text: $newMessage)
                    .padding(10)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6))
                    .cornerRadius(20)
                    .foregroundColor(.primary)
                    .disabled(isUploading)

                // Send Button
                Button {
                    sendPendingMessage()
                } label: {
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.brand))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor((!newMessage.isEmpty || pendingImage != nil) ? Color.brand : .gray)
                    }
                }
                .disabled(isUploading || (newMessage.isEmpty && pendingImage == nil))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(red: 0.97, green: 0.97, blue: 0.99))
            .overlay(
                Divider()
                    .background(Color.gray.opacity(0.15)),
                alignment: .top
            )
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
            requestNotificationAuthorizationIfNeeded()
            showTabBar.wrappedValue = false
            Task {
                try? await chatManager.fetchMessages(for: chatPreview.id)
                await chatManager.startRealtimeSubscription(for: chatPreview.id)
            }
        }
        .onDisappear {
            if shouldRestoreTabBarOnDisappear {
                showTabBar.wrappedValue = true
            }
            chatManager.stopRealtimeSubscription()
            chatManager.currentMessages = []
        }
        .onChange(of: selectedItem) { _, item in
            guard let item = item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        withAnimation {
                            self.pendingImage = uiImage
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $pendingImage)
        }
    }
    
    private func requestNotificationAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("Notification authorization error: \(error)")
                } else {
                    print("Notifications granted: \(granted)")
                }
            }
        }
    }
    
    private func scheduleLocalNotificationFor(messageId: UUID, contentText: String?, imageUrl: String?, from senderName: String) {
        let content = UNMutableNotificationContent()
        content.title = senderName
        if let text = contentText, !text.isEmpty {
            content.body = text
        } else if imageUrl != nil {
            content.body = "صورة جديدة"
        } else {
            content.body = "رسالة جديدة"
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: messageId.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func sendPendingMessage() {
        let textToSend = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let imgToSend = pendingImage
        
        newMessage = ""
        pendingImage = nil
        
        guard imgToSend != nil || !textToSend.isEmpty else { return }
        
        isUploading = true
        
        Task {
            do {
                var photoUrl: String? = nil
                if let img = imgToSend {
                    let compressed = img.resizeToMaxDimension(800) ?? img
                    photoUrl = try await SupabaseManager.shared.uploadPhotoAsync(
                        photo: compressed,
                        reportID: UUID().uuidString
                    )
                }
                
                if let photoUrl = photoUrl {
                    try await chatManager.sendMessage(
                        chatId: chatPreview.id,
                        content: textToSend.isEmpty ? nil : textToSend,
                        imageUrl: photoUrl
                    )
                } else if !textToSend.isEmpty {
                    try await chatManager.sendMessage(
                        chatId: chatPreview.id,
                        content: textToSend,
                        imageUrl: nil
                    )
                }
                await MainActor.run {
                    isUploading = false
                }
            } catch {
                print("Error sending message: \(error)")
                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
    
    private func deleteMessage(id: UUID) async {
        do {
            try await SupabaseManager.shared.client
                .from("messages")
                .delete()
                .eq("id", value: id)
                .execute()

            await MainActor.run {
                chatManager.currentMessages.removeAll { $0.id == id }
            }
        } catch {
            print("Failed to delete message: \(error)")
        }
    }
}

// MARK: - Image Picker wrapper for Camera usage
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - UIImage helper for resizing / compressing
extension UIImage {
    func resizeToMaxDimension(_ maxDimension: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if aspectRatio > 1 {
            newSize = CGSize(width: min(size.width, maxDimension), height: min(size.width, maxDimension) / aspectRatio)
        } else {
            newSize = CGSize(width: min(size.height, maxDimension) * aspectRatio, height: min(size.height, maxDimension))
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

