//
//  Plane.swift
//  iOSSwiftMetalCamera
//
//  Created by Bradley Griffith on 11/27/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

import UIKit

class Plane: Node {
    
     override func createVertex() {
        /*inverted
        let A = Vertex(x: -1.0, y: -1.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, s: 1.0, t: 1.0)
        let B = Vertex(x: -1.0, y:  1.0, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0, s: 1.0, t: 0.0)
        let C = Vertex(x:  1.0, y:  1.0, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0, s: 0.0, t: 0.0)
        let D = Vertex(x:  1.0, y: -1.0, z:   0.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0, s: 0.0, t: 1.0)*/
        
        let A = Vertex(x: -1.0, y:   1.0, z:   1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, s: 1, t: 0)
        let B = Vertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0, s: 1, t: 1)
        let C = Vertex(x:  1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0, s: 0, t: 1)
        let D = Vertex(x:  1.0, y:   1.0, z:   1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0, s: 0, t: 0)
        
        
        var verticesArray:Array<Vertex> = [
            A,B,C ,A,C,D   //Front
        ]
        self.vertices = verticesArray
    }
    init(device: MTLDevice, commandQ: MTLCommandQueue){
        
        var texture = MetalTexture(resourceName: "spiral", ext: "png", mipmaped: true)
        texture.loadTexture(device: device, commandQ: commandQ, flip: true)
        
        super.init(name: "Plane",  device: device, texture: texture.texture)
        
    }
    
    override init(name: String,  device: MTLDevice, texture : MTLTexture){
        super.init(name: name,  device: device, texture: texture)
    }
    
    
    
    
}