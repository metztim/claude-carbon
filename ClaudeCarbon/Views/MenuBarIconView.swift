//
//  MenuBarIconView.swift
//  ClaudeCarbon
//
//  Menu bar icon with pulse animation when actively consuming tokens.
//

import SwiftUI

struct MenuBarIconView: View {
    @ObservedObject var activityIndicator: ActivityIndicator

    var body: some View {
        Image(systemName: "leaf.fill")
            .symbolEffect(.pulse, isActive: activityIndicator.isActive)
    }
}
