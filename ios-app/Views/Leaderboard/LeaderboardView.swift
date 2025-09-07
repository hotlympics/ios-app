//
//  LeaderboardView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var showingDetailView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    // Initial loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        
                        Text("Loading leaderboard...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red.opacity(0.8))
                        
                        Text("Failed to load leaderboard")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            Task {
                                await viewModel.refresh()
                            }
                        }) {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    // Main content
                    VStack(spacing: 0) {
                        // Header with segmented control
                        VStack(spacing: 12) {
                            Text("Leaderboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            // Segmented Control
                            Picker("Leaderboard Type", selection: $viewModel.selectedType) {
                                ForEach(LeaderboardType.allCases, id: \.self) { type in
                                    Text(type.displayName)
                                        .tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            .onChange(of: viewModel.selectedType) { newType in
                                viewModel.switchLeaderboardType(newType)
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 8)
                        
                        // Content
                        if viewModel.hasEntries {
                            ScrollView {
                                VStack(spacing: 20) {
                                    // Podium for top 3
                                    if !viewModel.topThreeEntries.isEmpty {
                                        LeaderboardPodiumView(
                                            entries: viewModel.topThreeEntries,
                                            onEntryTap: { entry in
                                                viewModel.selectEntry(entry)
                                            }
                                        )
                                        .padding(.top, 20)
                                    }
                                    
                                    // Divider
                                    if !viewModel.remainingEntries.isEmpty {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 1)
                                            .padding(.horizontal, 20)
                                    }
                                    
                                    // Full list (4th place onwards)
                                    if !viewModel.remainingEntries.isEmpty {
                                        LeaderboardListView(
                                            entries: viewModel.remainingEntries,
                                            onEntryTap: { entry in
                                                viewModel.selectEntry(entry)
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                            .refreshable {
                                await viewModel.refresh()
                            }
                        } else {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray.opacity(0.3))
                                
                                Text("No entries yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Text("Start rating to see the leaderboard!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $viewModel.showingDetail) {
            if let selectedEntry = viewModel.selectedEntry {
                LeaderboardDetailView(
                    entry: selectedEntry,
                    isPresented: $viewModel.showingDetail
                )
                .onDisappear {
                    viewModel.clearSelection()
                }
            }
        }
    }
}

#Preview {
    LeaderboardView()
}