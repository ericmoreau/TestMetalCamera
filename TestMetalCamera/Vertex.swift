//
//  Vertex.swift
//  HelloMetal
//
//  Created by Andrew K. on 10/23/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

struct Vertex{
    
    var x,y,z: Float     // position data
    var r,g,b,a: Float   // color data
    var s,t:Float        //Texture coordinate
    
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a,s,t]
    }
    
};
