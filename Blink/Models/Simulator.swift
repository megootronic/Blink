//
//  Simulator.swift
//  Blink
//
//  Model representing a booted iOS simulator
//

import Foundation

struct Simulator: Identifiable, Hashable {
    let id: String // UDID
    let name: String
    let runtime: String
    let state: String
    let runningApp: AppInfo?

    struct AppInfo: Hashable {
        let bundleID: String
        let displayName: String
    }
}
