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
            GeometryReader { geo in
                let imageWidth: CGFloat = 350
                let leftInset = max((geo.size.width - imageWidth) / 2, 0)
                let extraTitleLeading = max(leftInset - 20, 0)
                let imageRightEdge = leftInset + imageWidth
                let menuCurrentRight = geo.size.width - 20
                let extraMenuTrailing = max(menuCurrentRight - imageRightEdge, 0)
                
                ZStack {
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                    
                    if viewModel.isLoading && viewModel.entries.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            Text("Loading leaderboard...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    } else if let errorMessage = viewModel.errorMessage {
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
                                Task { await viewModel.refresh() }
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
                        VStack(spacing: 0) {
                            HStack {
                                Text("Leaderboard")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.leading, extraTitleLeading)
                                Spacer()
                                Menu {
                                    ForEach(LeaderboardType.allCases, id: \.self) { type in
                                        Button { viewModel.switchLeaderboardType(type) } label: {
                                            Label(type.displayName, systemImage: viewModel.selectedType == type ? "checkmark" : "")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedType.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(6)
                                }
                                .padding(.trailing, extraMenuTrailing)
                            }
                            .padding(.top)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                            
                            if viewModel.hasEntries {
                                ScrollView {
                                    VStack(spacing: 20) {
                                        LeaderboardListView(
                                            entries: Array(viewModel.entries.prefix(10)),
                                            onEntryTap: { entry in viewModel.selectEntry(entry) }
                                        )
                                        .padding(.horizontal)
                                        .padding(.top, 20)
                                    }
                                    .padding(.bottom, 20)
                                }
                                .refreshable { await viewModel.refresh() }
                            } else {
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
        }
        .fullScreenCover(isPresented: $viewModel.showingDetail) {
            if let selectedEntry = viewModel.selectedEntry {
                LeaderboardDetailView(
                    entry: selectedEntry,
                    isPresented: $viewModel.showingDetail
                )
                .onDisappear { viewModel.clearSelection() }
            }
        }
    }
}

#Preview {
    LeaderboardView()
}
