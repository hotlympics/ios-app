//
//  DemoMyPhotosView.swift
//  ios-app
//
//  Created for demo view purposes
//

import SwiftUI

struct DemoMyPhotosView: View {
    @State private var showingSignIn = false
    let onAuthenticationSuccess: (() -> Void)?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            // Blurred demo content layer
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("My Photos")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Demo pool selection bar
                    HStack {
                        Text("Select up to 2 photos for the rating pool (2/2 selected)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        Button(action: {}) {
                            Text("Save Pool Selection")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .disabled(true)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray5))

                    Text("5/10 photos uploaded")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                // Photo grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(DemoPhotosData.photos) { photo in
                            DemoPhotoCellView(photo: photo)
                        }
                    }
                    .padding()
                }
            }
            .blur(radius: 2)

            // Sign-in CTA overlay
            VStack {
                Spacer()

                VStack(spacing: 8) {
                    Text("Ready to Find Out How Your Photos Compare?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button(action: {
                        showingSignIn = true
                    }) {
                        Text("Sign In or Sign Up")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(
                    Color(UIColor.systemGray6)
                        .opacity(0.95)
                )
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSignIn) {
            SignInView(onAuthenticationSuccess: onAuthenticationSuccess)
        }
    }
}

#Preview {
    DemoMyPhotosView(onAuthenticationSuccess: nil)
}
