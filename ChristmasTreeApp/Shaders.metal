//
//  Shaders.metal
//  Christmas_tree
//
//  Created by 🌈ALEX HUANG🏖️ on 2025-12-17.
//

#include <metal_stdlib>
using namespace metal;

struct PointGPU {
    float3 pos;
    float3 color;
};

struct Uniforms {
    float angle;
    float pitch;
    float camDist;
    float camHeight;
    float2 viewport;
};

struct VSOut {
    float4 position [[position]];
    float3 color;
    float  psize [[point_size]];
};

vertex VSOut points_vertex(const device PointGPU* pts [[buffer(0)]],
                           constant Uniforms& u [[buffer(1)]],
                           uint vid [[vertex_id]])
{
    float3 p = pts[vid].pos;

    // yaw rotate around Y (x,z)
    float ca = cos(u.angle);
    float sa = sin(u.angle);
    float xz_x = p.x * ca - p.z * sa;
    float xz_z = p.x * sa + p.z * ca;

    // pitch rotate (y, z)
    float cp = cos(u.pitch);
    float sp = sin(u.pitch);
    float yp = p.y * cp - xz_z * sp;
    float zp = p.y * sp + xz_z * cp;

    // camera shift
    zp = zp + u.camDist;
    yp = yp - u.camHeight;

    VSOut o;
    if (zp <= 0.1) {
        o.position = float4(2, 2, 0, 1); // clip
        o.color = float3(0);
        o.psize = 0.0;
        return o;
    }

    float f = (u.viewport.y * 0.63) / zp;
    float sx = (u.viewport.x * 0.5) + xz_x * f;
    float sy = (u.viewport.y * 0.5) - yp * f;

    // screen -> NDC
    float ndc_x = (sx / u.viewport.x) * 2.0 - 1.0;
    float ndc_y = 1.0 - (sy / u.viewport.y) * 2.0;

    o.position = float4(ndc_x, ndc_y, 0.0, 1.0);
    o.color = pts[vid].color;

    // point size by depth (similar to pygame version)
    float size = clamp(3.6 - zp * 0.13, 1.0, 6.0);
    o.psize = size;
    return o;
}

fragment float4 points_fragment(VSOut in [[stage_in]],
                                float2 pc [[point_coord]])
{
    // circular point sprite + soft edge glow
    float2 c = pc * 2.0 - 1.0;
    float r2 = dot(c, c);
    float alpha = smoothstep(1.0, 0.6, r2);
    float glow  = smoothstep(1.3, 0.0, r2);

    float3 col = in.color * (0.8 + 0.5 * glow);
    return float4(col, alpha);
}
