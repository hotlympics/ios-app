//
//  PoolSelectionBarView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct PoolSelectionBarView: View {
    let selectedCount: Int
    let hasChanges: Bool
    let isUpdating: Bool
    let onSave: () -> Void
    
    var body: some View {
        HStack {
            Text("Select up to 2 photos for the rating pool (\(selectedCount)/2 selected)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: onSave) {
                if isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Save Pool Selection")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(hasChanges && !isUpdating ? Color.green : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(6)
            .disabled(!hasChanges || isUpdating)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray5))
    }
}