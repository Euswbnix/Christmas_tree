//
//  MetalView.swift
//  Christmas_tree
//
//  Created by 🌈ALEX HUANG🏖️ on 2025-12-17.
//
import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create and retain renderer
        let renderer = Renderer(view: view)
        context.coordinator.renderer = renderer

        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // no-op
    }

    final class Coordinator {
        var renderer: Renderer?
    }
}
