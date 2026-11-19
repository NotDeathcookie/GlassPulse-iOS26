#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] float2 liquidRipple(
    float2 position,
    float2 origin,
    float time,
    float amplitude,
    float frequency
) {
    float2 delta = position - origin;
    float dist = length(delta);
    float decay = exp(-dist * 0.0085);
    float wave = sin(dist * frequency - time * 6.5) * amplitude * decay;
    float2 dir = dist > 0.0001 ? (delta / dist) : float2(0.0, 0.0);
    return position + dir * wave;
}

[[ stitchable ]] half4 chromaticPrism(
    float2 position,
    SwiftUI::Layer layer,
    float intensity,
    float time
) {
    float shift = intensity * (1.0 + 0.25 * sin(time * 2.5));
    half4 r = layer.sample(position + float2(shift, 0.0));
    half4 g = layer.sample(position);
    half4 b = layer.sample(position - float2(shift, 0.0));
    return half4(r.r, g.g, b.b, g.a);
}
