//
//  LeaderboardViewModel.swift
//  ios-app
//
//  Created on 25/08/2025.
//

import Foundation
import SwiftUI

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedType: LeaderboardType = .femaleTop
    @Published var selectedEntry: LeaderboardEntry?
    @Published var showingDetail = false
    
    private let service = LeaderboardService.shared
    
    var topThreeEntries: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }
    
    var remainingEntries: [LeaderboardEntry] {
        guard entries.count > 3 else { return [] }
        return Array(entries.dropFirst(3))
    }
    
    var hasEntries: Bool {
        !entries.isEmpty
    }
    
    init() {
        Task {
            await loadLeaderboard()
        }
    }
    
    func loadLeaderboard(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.fetchLeaderboard(
                type: selectedType,
                forceRefresh: forceRefresh
            )
            
            withAnimation(.easeInOut(duration: 0.3)) {
                self.entries = response.entries
            }
        } catch {
            errorMessage = "Failed to load leaderboard"
            print("Error loading leaderboard: \(error)")
        }
        
        isLoading = false
    }
    
    func switchLeaderboardType(_ type: LeaderboardType) {
        guard type != selectedType else { return }
        
        selectedType = type
        selectedEntry = nil
        showingDetail = false
        
        Task {
            await loadLeaderboard()
        }
    }
    
    func selectEntry(_ entry: LeaderboardEntry) {
        selectedEntry = entry
        showingDetail = true
    }
    
    func clearSelection() {
        selectedEntry = nil
        showingDetail = false
    }
    
    func refresh() async {
        await loadLeaderboard(forceRefresh: true)
    }
}