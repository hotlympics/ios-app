//
//  GenderDOBSetupView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct GenderDOBSetupView: View {
    @State private var selectedGender: String = "unknown"
    @State private var dateOfBirth = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onSubmit: (String, String) async -> Bool
    let onLogout: () -> Void
    
    // Calculate the maximum date (today) and minimum date (120 years ago)
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let maxDate = Date()
        let minDate = calendar.date(byAdding: .year, value: -120, to: maxDate) ?? maxDate
        return minDate...maxDate
    }
    
    // Format the date for the API
    private var formattedDateOfBirth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: dateOfBirth)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Complete Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please provide your gender and date of birth to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Form
            VStack(spacing: 24) {
                // Gender Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gender")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        GenderButton(
                            title: "Male",
                            isSelected: selectedGender == "male",
                            action: { selectedGender = "male" }
                        )
                        
                        GenderButton(
                            title: "Female",
                            isSelected: selectedGender == "female",
                            action: { selectedGender = "female" }
                        )
                    }
                }
                
                // Date of Birth
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date of Birth")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    DatePicker(
                        "",
                        selection: $dateOfBirth,
                        in: dateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: submitProfile) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Continue")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
                }
                .disabled(!isFormValid || isLoading)
                
                Button(action: onLogout) {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
    
    private var isFormValid: Bool {
        selectedGender != "unknown"
    }
    
    private func submitProfile() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            let success = await onSubmit(selectedGender, formattedDateOfBirth)
            
            await MainActor.run {
                isLoading = false
                if !success {
                    errorMessage = "Failed to update profile. Please try again."
                }
            }
        }
    }
}

// Gender selection button component
struct GenderButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

#Preview {
    GenderDOBSetupView(
        onSubmit: { _, _ in true },
        onLogout: { }
    )
}