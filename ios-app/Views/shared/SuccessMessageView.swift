//
//  SuccessMessageView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct SuccessMessageView: View {
    let message: String
    let isSuccess: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isSuccess ? .white : .red)
            Text(message)
                .font(.caption)
            Spacer()
        }
        .padding()
        .background(isSuccess ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}