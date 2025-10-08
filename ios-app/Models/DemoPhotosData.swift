//
//  DemoPhotosData.swift
//  ios-app
//
//  Created for demo view purposes
//

import Foundation

struct DemoPhoto: Identifiable {
    let id: String
    let imageName: String
    let rating: Int
    let wins: Int
    let losses: Int
    let isInPool: Bool
}

struct DemoPhotosData {
    static let photos: [DemoPhoto] = [
        DemoPhoto(
            id: "demo-1",
            imageName: "demo-photo1",
            rating: 2425,
            wins: 144,
            losses: 12,
            isInPool: true
        ),
        DemoPhoto(
            id: "demo-2",
            imageName: "demo-photo2",
            rating: 2380,
            wins: 139,
            losses: 13,
            isInPool: false
        ),
        DemoPhoto(
            id: "demo-3",
            imageName: "demo-photo3",
            rating: 2111,
            wins: 120,
            losses: 21,
            isInPool: true
        ),
        DemoPhoto(
            id: "demo-4",
            imageName: "demo-photo4",
            rating: 2490,
            wins: 151,
            losses: 3,
            isInPool: false
        ),
        DemoPhoto(
            id: "demo-5",
            imageName: "demo-photo5",
            rating: 2140,
            wins: 124,
            losses: 18,
            isInPool: false
        )
    ]

    static let poolSelections = Set<String>(["demo-1", "demo-3"])
}
