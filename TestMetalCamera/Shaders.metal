//
//  Shaders.metal
//  HelloMetal
//
//  Created by Main Account on 10/2/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn{
    packed_float3 position;
    packed_float4 color;
    packed_float2 texCoord;
};

struct VertexOut{
    float4 position [[position]];  //1
    float4 color;
    float2 texCoord;
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut basic_vertex(
                              const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms&  uniforms    [[ buffer(1) ]],           //1
                              unsigned int vid [[ vertex_id ]]) {
    
    float4x4 mv_Matrix = uniforms.modelMatrix;                     //2
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    VertexIn VertexIn = vertex_array[vid];
    
    VertexOut VertexOut;
    VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);  //3
    VertexOut.color = VertexIn.color;
    VertexOut.texCoord = VertexIn.texCoord;
    
    return VertexOut;
}

fragment float4 basic_fragment(VertexOut interpolated [[stage_in]],
                              texture2d<float> tex2d [[texture(0)]],
                              sampler sampler2D [[sampler(0)]]) {  //1
    float4 color = tex2d.sample(sampler2D, interpolated.texCoord);
    return color;
    //return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]); //2
}
