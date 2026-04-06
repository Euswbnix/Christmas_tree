//
//  ContentView.swift
//  Christmas_tree
//
//  Created by 🌈ALEX HUANG🏖️ on 2025-12-17.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            MetalView()
                .ignoresSafeArea()

            HStack {
                Text("Merry Christmas")
                    .font(.custom("Times New Roman Italic", size: 38))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.35), radius: 6)
                    .padding(.leading, 60)

                Spacer()
            }
        }
    }
}
