#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    packed_float3 position;
    packed_float4 color;
};

struct VertexOut {
    float4 position[[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut basic_vertex(const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms& uniforms     [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
    float4x4 mv_matrix = uniforms.modelMatrix;
    float4x4 proj_matrix = uniforms.projectionMatrix;

    VertexIn vertexIn = vertex_array[vid];
    VertexOut vertexOut;
    vertexOut.position = proj_matrix * mv_matrix * float4(vertexIn.position, 1);
    vertexOut.color = vertexIn.color;
    return vertexOut;
}

fragment half4 basic_fragment(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}
