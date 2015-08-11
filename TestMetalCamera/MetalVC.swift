//
//  ViewController.swift
//  HelloMetal
//
//  Created by Main Account on 10/2/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit
import Metal
import QuartzCore

protocol MetalVCDelegate : class{
    func updateLogic(timeSinceLastUpdate:CFTimeInterval)
    func renderObjects(drawable:CAMetalDrawable)
}

class MetalVC: UIViewController {
    
    var debugView = UITextView()
    
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil
    var projectionMatrix: Matrix4!
    var lastFrameTimestamp: CFTimeInterval = 0.0
    //var objectToDraw: Node!
    
    var bufferProvider : BufferProvider!
    var sceneObjects = [String: Node]()
    
    weak var metalViewControllerDelegate:MetalVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self._setupProjectionMatrix()
        
        self.setupMetalEnvironment()
        
        self.setupDebugEnvironment()
        
        timer = CADisplayLink(target: self, selector: Selector("newFrame:"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
    }
    
    func setupDebugEnvironment(){
        debugView = UITextView(frame: self.view.bounds.rectByInsetting(dx: 10, dy: 10))
        debugView.backgroundColor = UIColor.clearColor()
        self.view.addSubview(debugView)
        debugView.textColor = UIColor.blueColor()
        debugView.font = UIFont.systemFontOfSize(20)
        debugView.text = ""
        
        
        
    }
    
    func setupMetalEnvironment(){
        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        
        commandQueue = device.newCommandQueue()
        
        self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: sizeof(Float) * Matrix4.numberOfElements() * 2)
        
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.Add;
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.Add;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.One;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.One;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.OneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.OneMinusSourceAlpha;
        
        var pipelineError : NSError?
        pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor, error: &pipelineError)
        if pipelineState == nil {
            println("Failed to create pipeline state, error \(pipelineError)")
        }
    }
    
    private func _setupProjectionMatrix() {
        projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: Float(view.bounds.size.width / view.bounds.size.height), nearZ: 0.1, farZ: 100.0)
   
    }
    
    
    func render() {
        var drawable = metalLayer.nextDrawable()
        self.metalViewControllerDelegate?.renderObjects(drawable)
        
    }
    
    
    func newFrame(displayLink: CADisplayLink){
        
        if lastFrameTimestamp == 0.0
        {
            lastFrameTimestamp = displayLink.timestamp
        }
        
        var elapsed:CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
        lastFrameTimestamp = displayLink.timestamp
        
        gameloop(timeSinceLastUpdate: elapsed)
    }
    
    func gameloop(#timeSinceLastUpdate: CFTimeInterval) {
        
        self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate)
        
        autoreleasepool {
            self.render()
        }
    }
    
}

