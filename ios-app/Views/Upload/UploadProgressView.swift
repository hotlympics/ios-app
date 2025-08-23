//
//  UploadProgressView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct UploadProgressView: View {
    let status: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text(status)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if progress > 0 {
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("\(Int(progress))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 60)
    }
}