//
//  Node.swift
//  HelloMetal
//
//  Created by Andrew K. on 10/23/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

class Node {
    
    var time:CFTimeInterval = 0.0
    
    var name: String
    var vertexCount: Int!
    var vertexBuffer: MTLBuffer!
    var device: MTLDevice
    
    var texture : MTLTexture
    var vertices : Array<Vertex>! = Array<Vertex>()
    lazy var samplerState : MTLSamplerState? = Node.defaultSampler(self.device)
    
    
    
    var positionX:Float = 0.0
    var positionY:Float = 0.0
    var positionZ:Float = 0.0
    
    var rotationX:Float = 0.0
    var rotationY:Float = 0.0
    var rotationZ:Float = 0.0
    var scale:Float     = 1.0
    
    //TODO: Should we set individual scale?
    var scaleX:Float    = 1.0
    var scaleY:Float    = 1.0
    var scaleZ:Float    = 1.0
    
    func createVertex(){}
    
    
    
    init(name: String,  device: MTLDevice, texture : MTLTexture){
        
        var vertexData = Array<Float>()
        self.name = name
        self.device = device
        
        self.texture = texture
        
        
        self.createVertex()
        vertexCount = vertices.count
        for vertex in vertices{
            vertexData += vertex.floatBuffer()
        }
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: nil)

        
        
    }
    
    func render(renderEncoder:MTLRenderCommandEncoder, bufferProvider: BufferProvider, pipelineState: MTLRenderPipelineState, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4, clearColor: MTLClearColor?){
        
            //For now cull mode is used instead of depth buffer
            renderEncoder.setCullMode(MTLCullMode.Front)
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
            
            var nodeModelMatrix = self.modelMatrix()
            //nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
            
            let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix, modelViewMatrix: nodeModelMatrix)
            
            renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
        
        
            renderEncoder.setFragmentTexture(texture, atIndex: 0)
            if let samplerState = samplerState{
                renderEncoder.setFragmentSamplerState(samplerState, atIndex: 0)
            }
            renderEncoder.drawPrimitives(
                    .Triangle,
                    vertexStart: 0,
                    vertexCount: vertexCount
            )
            
   
        
    }
    
    func modelMatrix() -> Matrix4 {
        var matrix = Matrix4()
        matrix.translate(positionX, y: positionY, z: positionZ)
        matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
        matrix.scale(scale, y: scale, z: scale)
        return matrix
    }
    
    func updateWithDelta(delta: CFTimeInterval){
        time += delta
    }
    
    class func defaultSampler(device: MTLDevice) ->MTLSamplerState{
        var pSamplerDescriptor: MTLSamplerDescriptor? = MTLSamplerDescriptor();
        
        if let sampler = pSamplerDescriptor{
            sampler.minFilter = MTLSamplerMinMagFilter.Nearest
            sampler.magFilter = MTLSamplerMinMagFilter.Nearest
            sampler.mipFilter = MTLSamplerMipFilter.Nearest
            sampler.maxAnisotropy = 1
            sampler.sAddressMode = MTLSamplerAddressMode.ClampToEdge
            sampler.tAddressMode = MTLSamplerAddressMode.ClampToEdge
            sampler.rAddressMode = MTLSamplerAddressMode.ClampToEdge
            sampler.normalizedCoordinates = true
            sampler.lodMinClamp = 0
            sampler.lodMaxClamp = FLT_MAX
        }
        else{
            println("error Failed creating a sampler Descriptor")
        }
        return device.newSamplerStateWithDescriptor(pSamplerDescriptor!)
    }
   
    
}
