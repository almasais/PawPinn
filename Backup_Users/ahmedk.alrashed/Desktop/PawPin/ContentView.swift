//
//  ContentView.swift
//  PawPin

import SwiftUI

struct ContentView: View {
    
    @StateObject var chatVM = ChatViewModel()
    @State private var selectedTab = "Home"
    @State private var showTabBar = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case "Home":
                    NavigationStack {
                        HomeView()
                    }
                case "Map":
                    NavigationStack {
                        MapViewScreen()
                    }
                case "Chat":
                    NavigationStack {
                        ChatListView(showTabBar: $showTabBar)
                            .environmentObject(chatVM)
                    }
                case "Search":
                    NavigationStack {
                        CameraView()
                    }
                default:
                    NavigationStack {
                        HomeView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showTabBar {
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(
                        .move(edge: .bottom).combined(with: .opacity)
                    )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut(duration: 0.25), value: showTabBar)
    }
}
