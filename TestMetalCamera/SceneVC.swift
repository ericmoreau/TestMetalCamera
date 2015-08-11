//
//  ViewController.swift
//  TestMetalCamera
//
//  Created by emoreau on 2015-08-03.
//  Copyright (c) 2015 emoreau. All rights reserved.
//

import UIKit

class SceneVC: CaptureVC, MetalVCDelegate{
    
    
    var worldModelMatrix:Matrix4!
    
    
    let panSensivity:Float = 5.0
    var lastPanLocation: CGPoint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        worldModelMatrix = Matrix4()
        worldModelMatrix.translate(0.0, y: 0.0, z: 0)
        worldModelMatrix.rotateAroundX(Matrix4.degreesToRad(0), y: 0 , z: 0)
        
        
        
        var foreground = Plane(device: device, commandQ:commandQueue)
        foreground.scale = 0.5
        foreground.positionZ = -2
       // foreground.texture = nil
        var background = Plane(device: device, commandQ:commandQueue)
        background.scale = 1
        background.positionZ = -2
        
        sceneObjects["Background"] = background
        sceneObjects["Foreground"] = foreground
        
       
        

        
        
        self.metalViewControllerDelegate = self
        setupGesture()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        cameraSessionController.startColorCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.resize()
    }
    
    func resize() {
        if let window = view.window {
            let scale = window.screen.nativeScale
            let bounds = view.bounds
            let size = bounds.size
            
            view.contentScaleFactor = scale
            
            metalLayer.frame = bounds
            metalLayer.drawableSize = CGSizeMake(size.width * scale, size.height * scale)
        }
    }
    
    //MARK: - MetalViewControllerDelegate
    func renderObjects(drawable:CAMetalDrawable) {
        dispatch_semaphore_wait(bufferProvider.availableResourcesSemaphore, DISPATCH_TIME_FOREVER)
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0, blue: 0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .Store
        
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.addCompletedHandler { (commandBuffer) -> Void in
            var temp = dispatch_semaphore_signal(self.bufferProvider.availableResourcesSemaphore)
        }
        
        let renderEncoderOpt = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        if let renderEncoder = renderEncoderOpt {
           sceneObjects["Background"]!.render(renderEncoder, bufferProvider: self.bufferProvider ,pipelineState: pipelineState, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
            sceneObjects["Foreground"]!.render(renderEncoder, bufferProvider: self.bufferProvider ,pipelineState: pipelineState, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
           
            renderEncoder.endEncoding()
        }
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
        
    }
    
    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        for (string, object) in sceneObjects{
            object.updateWithDelta(timeSinceLastUpdate)
        }
    }
    
    func setupGesture(){
        var pan = UIPanGestureRecognizer(target: self, action: Selector("pan:"))
        self.view.addGestureRecognizer(pan)
    }
    
    func pan(panGesture:UIPanGestureRecognizer){
        if panGesture.state == UIGestureRecognizerState.Changed{
            
            var pointInview = panGesture.locationInView(self.view)
            var xDelta = Float((lastPanLocation.x - pointInview.x) / self.view.bounds.width) * panSensivity
            var yDelta = Float((lastPanLocation.y - pointInview.y) / self.view.bounds.height) * panSensivity
            for (string, object) in sceneObjects {
                object.rotationY -= xDelta
                object.rotationX -= yDelta
            }
            lastPanLocation = pointInview
        }
        else if panGesture.state == UIGestureRecognizerState.Began{
            lastPanLocation = panGesture.locationInView(self.view)
        }
        
    }
    
}

