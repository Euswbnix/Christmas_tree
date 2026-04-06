//
//  Untitled.swift
//  Christmas_tree
//
//  Created by 🌈ALEX HUANG🏖️ on 2025-12-17.
//

import MetalKit
import simd

// === Tunables (match your pygame version) ===
private let TREE_POINTS = 50_000
private let GROUND_POINTS = 4_000
private let STAR_POINTS = 1_200
private let HEART_POINTS = 1_000

private let TREE_HEIGHT: Float = 12.0
private let CAM_DIST: Float = 13.0
private let CAM_HEIGHT: Float = 6.0
private let PITCH: Float = -0.25

// === GPU structs (must match Shaders.metal) ===
private struct PointGPU {
    var pos: SIMD3<Float>
    var color: SIMD3<Float>
}

private struct Uniforms {
    var angle: Float
    var pitch: Float
    var camDist: Float
    var camHeight: Float
    var viewport: SIMD2<Float>
}

final class Renderer: NSObject, MTKViewDelegate {

    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState

    private var pointsBuffer: MTLBuffer!
    private var pointsCount: Int = 0
    private var uniformBuffer: MTLBuffer!

    private var angle: Float = 0

    init(view: MTKView) {
        guard let dev = view.device,
              let q = dev.makeCommandQueue(),
              let lib = dev.makeDefaultLibrary()
        else { fatalError("Metal setup failed") }

        self.queue = q

        // Build pipeline
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = lib.makeFunction(name: "points_vertex")
        desc.fragmentFunction = lib.makeFunction(name: "points_fragment")
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        self.pipeline = try! dev.makeRenderPipelineState(descriptor: desc)

        super.init()

        // Generate scene once
        let pts = Self.buildScenePoints()
        self.pointsCount = pts.count
        self.pointsBuffer = dev.makeBuffer(bytes: pts,
                                           length: MemoryLayout<PointGPU>.stride * pts.count,
                                           options: .storageModeShared)
        self.uniformBuffer = dev.makeBuffer(length: MemoryLayout<Uniforms>.stride,
                                            options: .storageModeShared)

        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.delegate = self
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // no-op
    }

    func draw(in view: MTKView) {
        guard let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: rpd)
        else { return }

        angle += 0.0045

        // Update uniforms
        var u = Uniforms(
            angle: angle,
            pitch: PITCH,
            camDist: CAM_DIST,
            camHeight: CAM_HEIGHT,
            viewport: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
        )
        memcpy(uniformBuffer.contents(), &u, MemoryLayout<Uniforms>.stride)

        enc.setRenderPipelineState(pipeline)
        enc.setVertexBuffer(pointsBuffer, offset: 0, index: 0)
        enc.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

        enc.drawPrimitives(type: .point, vertexStart: 0, vertexCount: pointsCount)

        enc.endEncoding()
        cmd.present(drawable)
        cmd.commit()
    }
}

// === Point cloud generation (CPU once) ===
private extension Renderer {

    static func buildScenePoints() -> [PointGPU] {
        var pts: [PointGPU] = []
        pts.reserveCapacity(TREE_POINTS + GROUND_POINTS + STAR_POINTS + HEART_POINTS)

        func rgb(_ r: Int, _ g: Int, _ b: Int) -> SIMD3<Float> {
            SIMD3<Float>(Float(r) / 255.0, Float(g) / 255.0, Float(b) / 255.0)
        }

        @inline(__always)
        func lerp(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> {
            a + (b - a) * t
        }

        // --- Tree: 70% spiral + 30% fill ---
        let loops: Float = 9
        let spiralN = Int(Float(TREE_POINTS) * 0.7)

        for _ in 0..<spiralN {
            let u = Float.random(in: 0...1)
            let h = pow(u, 1.6)
            let y = TREE_HEIGHT * h + 0.2

            var baseR = pow(1 - h, 1.1) * 3.2
            let bw = max(0.0, sin((h * 5.8 + 0.15) * Float.pi * 2))
            baseR *= (1.0 + 0.65 * bw)

            let t = u * loops * Float.pi * 2
            let ang = t + Float.random(in: -0.22...0.22)
            let r = baseR * Float.random(in: 0.85...1.08)

            let x = cos(ang) * r
            let z = sin(ang) * r

            // Purple → white gradient by height
            let purple = SIMD3<Float>(0.85, 0.55, 1.0)
            let white  = SIMD3<Float>(1.0, 0.95, 1.0)
            let tcol = pow(h, 0.85)
            let color = lerp(purple, white, tcol)

            pts.append(PointGPU(pos: SIMD3<Float>(x, y, z), color: color))
        }

        let fillN = TREE_POINTS - spiralN
        for _ in 0..<fillN {
            let h = pow(Float.random(in: 0...1), 1.9)
            let y = TREE_HEIGHT * h + 0.2 + Float.random(in: -0.08...0.08)

            var baseR = pow(1 - h, 1.1) * 4.3
            let bw = max(0.0, sin((h * 5.8 + 0.15) * Float.pi * 2))
            baseR *= (1.0 + 0.65 * bw)

            let r = baseR * sqrt(Float.random(in: 0...1))
            let a = Float.random(in: 0...(Float.pi * 2))

            let x = cos(a) * r + Float.random(in: -0.08...0.08)
            let z = sin(a) * r + Float.random(in: -0.08...0.08)

            let purpleFill = SIMD3<Float>(0.55, 0.35, 0.8)
            let white = SIMD3<Float>(1.0, 0.95, 1.0)
            let tcol = pow(h, 1.1)
            let color = lerp(purpleFill, white, tcol)
            pts.append(PointGPU(pos: SIMD3<Float>(x, y, z), color: color))
        }

        // --- Ground rings ---
        let rings: [Float] = [4.6, 6.0, 7.4, 8.8, 10.2, 11.4]
        for _ in 0..<GROUND_POINTS {
            let ring = rings.randomElement()!
            let r = ring + Float.random(in: -0.6...0.6) * 0.5
            let t = Float.random(in: 0...(Float.pi * 2))
            let x = cos(t) * r
            let z = sin(t) * r
            let y: Float = -0.25

            let c = (Float.random(in: 0...1) < 0.15) ? Int.random(in: 235...255) : Int.random(in: 190...235)
            pts.append(PointGPU(pos: SIMD3<Float>(x, y, z), color: rgb(c, c, 255)))
        }

        // --- Stars ---
        for _ in 0..<STAR_POINTS {
            let x = Float.random(in: -18...18)
            let z = Float.random(in: -18...18)
            let y = Float.random(in: 3...18)
            let base = Int.random(in: 215...255)
            pts.append(PointGPU(pos: SIMD3<Float>(x, y, z), color: rgb(base, base, 255)))
        }

        // --- Heart (implicit shape) ---
        let scale: Float = 0.9
        let topY: Float = TREE_HEIGHT + 0.05
        let targetTotal = TREE_POINTS + GROUND_POINTS + STAR_POINTS + HEART_POINTS
        while pts.count < targetTotal {
            let x = Float.random(in: -1.3...1.3)
            let y = Float.random(in: -1.4...1.4)
            let f = pow(x * x + y * y - 1.0, 3) - x * x * pow(y, 3)
            if f <= 0 {
                let wx = x * scale * 0.8
                let wy = topY + (y + 1.0) * scale * 0.5
                let wz = Float.random(in: -0.18...0.18)

                let dist = hypot(x, y)
                let factor = max(0.35, 1.15 - 0.5 * dist)

                var g = Int(130 * factor + 80)
                var b = Int(190 * factor + 70)
                g = max(120, min(255, g))
                b = max(120, min(255, b))

                pts.append(PointGPU(pos: SIMD3<Float>(wx, wy, wz), color: rgb(255, g, b)))
            }
        }

        return pts
    }
}
