//
//  BufferProvider.swift
//  HelloMetal
//
//  Created by emoreau on 2015-07-30.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

import Foundation
import Metal

class BufferProvider {
    let inflightBuffersCount : Int
    private var uniformsBuffers: [MTLBuffer]
    private var availableBufferIndex: Int = 0
    var availableResourcesSemaphore:dispatch_semaphore_t
    
   
    
    init (device:MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer:Int){
        availableResourcesSemaphore = dispatch_semaphore_create(inflightBuffersCount)
        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer]()
        for i in 0...inflightBuffersCount-1{
            var uniformsBuffer = device.newBufferWithLength(sizeOfUniformsBuffer, options: nil)
            uniformsBuffers.append(uniformsBuffer)
        }
    }
    
    func nextUniformsBuffer(projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer{
        var buffer = uniformsBuffers[availableBufferIndex]
        
        var bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw(), sizeof(Float)*Matrix4.numberOfElements())
        memcpy(bufferPointer + sizeof(Float) * Matrix4.numberOfElements(), projectionMatrix.raw(), sizeof(Float)*Matrix4.numberOfElements())
        
        availableBufferIndex++
        if availableBufferIndex == inflightBuffersCount{
            availableBufferIndex = 0
        }
        return buffer
    }
    
    deinit{
        for i in 0...self.inflightBuffersCount{
            dispatch_semaphore_signal(self.availableResourcesSemaphore)
        }
    }
}
