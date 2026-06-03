//
//  ReportAPet.swift
//  PawPin
//

import SwiftUI
import PhotosUI
import MapKit

struct ReportPetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddReportViewModel()
    @State private var showPhotoPicker = false
    @State private var photoItem: PhotosPickerItem? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Photo Picker
                ZStack {
                    if let image = viewModel.selectedPhoto {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color.brand)
                                    Text("Add Pet Photo")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    
                    if viewModel.isAnalyzing {
                        ZStack {
                            Color.black.opacity(0.5).clipShape(RoundedRectangle(cornerRadius: 16))
                            VStack {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Analyzing...").foregroundColor(.white).font(.caption).padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .onTapGesture {
                    showPhotoPicker = true
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
                .onChange(of: photoItem) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.selectedPhoto = uiImage
                                viewModel.analyzePhoto()
                            }
                        }
                    }
                }
                
                // Type Switcher
                Picker("Report Type", selection: $viewModel.selectedReportType) {
                    Text("Lost Pet").tag("lost")
                    Text("Found Pet").tag("found")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Form Fields
                VStack(spacing: 16) {
                    Group {
                        CustomTextField(placeholder: "Breed (e.g. Persian)", text: $viewModel.breed, icon: "pawprint")
                        CustomTextField(placeholder: "Fur Colors (e.g. White, Black)", text: $viewModel.furColors, icon: "paintpalette")
                        CustomTextField(placeholder: "Eye Color", text: $viewModel.eyeColor, icon: "eye")
                        CustomTextField(placeholder: "Pattern (e.g. Solid, Tabby)", text: $viewModel.pattern, icon: "square.dashed")
                        CustomTextField(placeholder: "Ear Type (e.g. Pointed, Folded)", text: $viewModel.earType, icon: "ear")
                        CustomTextField(placeholder: "Size (e.g. Small, Medium)", text: $viewModel.size, icon: "ruler")
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    Group {
                        CustomTextField(placeholder: "Contact Info (Phone/Email)", text: $viewModel.contactInfo, icon: "phone")
                        if viewModel.selectedReportType == "lost" {
                            CustomTextField(placeholder: "Reward Amount (Optional)", text: $viewModel.rewardAmount, icon: "banknote")
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Save Button
                PrimaryButton(title: "Submit Report", isLoading: viewModel.isSaving) {
                    viewModel.saveReport()
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .navigationTitle("Report a Pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .onChange(of: viewModel.saveSuccess) { _, success in
            if success {
                dismiss()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.saveError != nil), actions: {
            Button("OK") { viewModel.saveError = nil }
        }, message: {
            Text(viewModel.saveError ?? "")
        })
    }
}
