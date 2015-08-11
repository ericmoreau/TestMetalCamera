//
//  CaptureVC.swift
//  TestMetalCamera
//
//  Created by emoreau on 2015-08-03.
//  Copyright (c) 2015 emoreau. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation
import Metal

class CaptureVC: MetalVC,  CameraSessionControllerDelegate, STSensorControllerDelegate {
    
    var cameraSessionController: CameraSessionController!
    
    // var videoTextureBuffer: MTLRenderPassDescriptor?
    var videoOutputTexture: MTLTexture?
    var textureWidth: Int?
    var textureHeight: Int?
    var textureCache: CVMetalTextureCacheRef?
    var unmanagedTextureCache: Unmanaged<CVMetalTextureCache>?
    var toRGBA : STDepthToRgba?
    let sensorController: STSensorController = STSensorController.sharedController()
    
    func manageDebugState(message: String){
        var messageOutput : String  = self.debugView.text
        messageOutput += "\r" + message
        self.debugView.text = messageOutput
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        self.setupCamera()
        self._createTextureCache()
        self.setupSensor()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidBecomeActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
    }
    
    func appDidBecomeActive() {
        if (sensorController.isConnected()){
            self.tryStartStreaming()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if(self.tryInitializeSensor() && self.sensorController.isConnected()){
            var stream = self.tryStartStreaming()
        }
        else{
            manageDebugState("Disconnected viewWillAppear: " + self.sensorController.isConnected().description)
            
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: SETUP
    func setupCamera(){
        self.cameraSessionController = CameraSessionController()
        self.cameraSessionController.delegate = self
        
        
    }
    func setupSensor(){
        sensorController.delegate = self
        
    }
    
    
    private func _createTextureCache() {
        //  Use a CVMetalTextureCache object to directly read from or write to GPU-based CoreVideo image buffers
        //    in rendering or GPU compute tasks that use the Metal framework. For example, you can use a Metal
        //    texture cache to present live output from a device’s camera in a 3D scene rendered with Metal.
        CVMetalTextureCacheCreate(nil, nil, device, nil, &unmanagedTextureCache)
        
        textureCache = unmanagedTextureCache!.takeRetainedValue()
    }
    
    
    //MARK: Initialize
    func tryInitializeSensor() -> Bool {
        let result = sensorController.initializeSensorConnection()
        if result == .AlreadyInitialized || result == .Success {
            return true
        }
        return false
    }
    
    func tryStartStreaming() -> Bool {
        if tryInitializeSensor() {
            let options : [NSObject : AnyObject] = [
                kSTStreamConfigKey: NSNumber(integer: STStreamConfig.Depth640x480.rawValue),
                kSTFrameSyncConfigKey: NSNumber(integer: STFrameSyncConfig.DepthAndRgb.rawValue),
                kSTHoleFilterConfigKey: true
            ]
            var error : NSError? = nil
            if STSensorController.sharedController().startStreamingWithOptions(options, error: &error) {
                let toRGBAOptions : [NSObject : AnyObject] = [
                    kSTDepthToRgbaStrategyKey : NSNumber(integer: STDepthToRgbaStrategy.RedToBlueGradient.rawValue)
                ]
                toRGBA = STDepthToRgba(options: toRGBAOptions, error: nil)
                manageDebugState("tryStartStreaming : startStreamingWithOptions")
                return true
            }
            
        }
        manageDebugState("tryStartStreaming : Failure")
        return false
        
        /*
        BOOL optionsAreValid = [_sensorController startStreamingWithOptions:@{kSTStreamConfigKey : @(streamConfig),
        kSTFrameSyncConfigKey : @(STFrameSyncDepthAndRgb),
        kSTHoleFilterConfigKey: @TRUE} // looks better without holes
        error:&error];
        */
    }
    
     func draw(){
        if let drawable = metalLayer.nextDrawable() {
            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = drawable.texture
            passDescriptor.colorAttachments[0].loadAction = .Clear
            passDescriptor.colorAttachments[0].storeAction = .Store
            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.0, 0.0, 1.0)
            
            let commandBuffer = commandQueue.commandBuffer()
            
            let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(passDescriptor)!
            
            commandEncoder.endEncoding()
            
            commandBuffer.presentDrawable(drawable)
            commandBuffer.commit()
        }
    }
    
    
    
    /*func generateMipmapsAcceleratedFromTexture(texture: MTLTexture, toTexture: MTLTexture, completionBlock:(texture: MTLTexture) -> Void) {
        let commandBuffer = commandQueue.commandBuffer()
        let commandEncoder = commandBuffer?.blitCommandEncoder()
        let origin = MTLOriginMake(0, 0, 0)
        let size = MTLSizeMake(texture.width, texture.height, 1)
        
        commandEncoder?.copyFromTexture(texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: origin, sourceSize: size, toTexture: toTexture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: origin)
        
        commandEncoder?.generateMipmapsForTexture(toTexture)
        commandEncoder?.endEncoding()
        commandBuffer?.addCompletedHandler({ (MTLCommandBuffer) -> Void in
            completionBlock(texture: texture)
        })
        commandBuffer?.commit()
    }*/
    
    func updateTextureFromSampleBuffer(sampleBuffer: CMSampleBuffer!, object:Node ) {
        var pixelBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        var sourceImage: CIImage = CIImage(CVPixelBuffer: pixelBuffer)
        
        var sourceExtent: CGRect = sourceImage.extent()
        var sourceAspect: CGFloat = sourceExtent.size.width / sourceExtent.size.height
        
        textureWidth = CVPixelBufferGetWidth(pixelBuffer)
        textureHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        /*if (textureWidth! < textureWidth!) {
        objectToDraw!.scaleX = Float(1.0 / sourceAspect)
        objectToDraw!.scaleY = 1.0
        } else {
        objectToDraw!.scaleX = 1.0
        objectToDraw!.scaleY = Float(1.0 / sourceAspect)
        }*/
        
        var texture: MTLTexture
        var pixelFormat: MTLPixelFormat = MTLPixelFormat.BGRA8Unorm
        var unmanagedTexture: Unmanaged<CVMetalTexture>?
        var status: CVReturn = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, textureWidth!, textureHeight!, 0, &unmanagedTexture)
        // Note: 0 = kCVReturnSuccess
        if (status == 0) {
            texture = CVMetalTextureGetTexture(unmanagedTexture?.takeRetainedValue());
            
            // Note: If performance becomes an issue or you know you dont need mipmapping here,
            //   you can remove the lines that follow and just use `videoPlane!.texture! = texture`
            let format = object.texture.pixelFormat
            let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format, width: Int(textureWidth!), height: Int(textureHeight!), mipmapped: true)
            var tempTexture = device!.newTextureWithDescriptor(desc)
            // TODO: USE METALTEXTURE OR FLIP THE IMAGE
            object.texture = texture
            /*self.generateMipmapsAcceleratedFromTexture(texture, toTexture: tempTexture, completionBlock: { (newTexture) -> Void in
            self.objectToDraw!.texture = newTexture
            })*/
        }
        
    }
    
    
    func imageFromPixels(pixels : UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
        
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let info = CGBitmapInfo()
        var bitmapInfo = CGBitmapInfo.ByteOrder32Big
        
        bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
        bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.NoneSkipLast.rawValue)
        let provider = CGDataProviderCreateWithCFData(NSData(bytes:pixels, length: width*height*4))
        
        let image = CGImageCreate(
            width,                       //width
            height,                      //height
            8,                           //bits per component
            8 * 4,                       //bits per pixel
            width * 4,                   //bytes per row
            colorSpace,                  //Quartz color space
            bitmapInfo,                  //Bitmap info (alpha channel?, order, etc)
            provider,                    //Source of data for bitmap
            nil,                         //decode
            false,                       //pixel interpolation
            kCGRenderingIntentDefault);  //rendering intent
        
        return UIImage(CGImage: image)
    }
    
    
    
    
    
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        /*for object in sceneObjects{
        self.updateTextureFromSampleBuffer(sampleBuffer, object: object)
        }*/
        //self.updateTextureFromSampleBuffer(sampleBuffer, object: sceneObjects["Background"]!)
       // manageDebugState("cameraSessionDidOutputSampleBuffer")
        self.sensorController.frameSyncNewColorBuffer(sampleBuffer)
    }
    
    
    
    //MARK:STSensorControllerDelegate
    func sensorDidConnect() {
        if tryStartStreaming() {
            manageDebugState("sensorDidConnect: Success")
        } else {
            manageDebugState("sensorDidConnect: Failed")
        }
        
    }
    func sensorDidDisconnect() {
        manageDebugState("sensorDidDisconnect:")
    }
    func sensorDidStopStreaming(reason: STSensorControllerDidStopStreamingReason) {
        manageDebugState("sensorDidStopStreaming:" + String( reason.rawValue))
        
    }
    func sensorDidLeaveLowPowerMode() {}
    func sensorBatteryNeedsCharging() {}
    
    func sensorDidOutputDepthFrame(depthFrame: STDepthFrame!) {
        manageDebugState("sensorDidOutputDepthFrame")
        /*if let renderer = toRGBA {
        var pixels = renderer.convertDepthFrameToRgba(depthFrame)
        depthFrame.C
        
        delegate.sensorDidOutputDepthFrame(buffer)
        //var image = imageFromPixels(pixels, width: Int(renderer.width), height: Int(renderer.height))!
        //self.sessionDelegate?.ManageFrameOutput(image)
        
        }*/
        
    }
    
    
    
    func sensorDidOutputInfraredFrame(irFrame: STInfraredFrame!) {}
    
    func sensorDidOutputSynchronizedDepthFrame(depthFrame: STDepthFrame!, andColorBuffer sampleBuffer: CMSampleBuffer!) {
        manageDebugState("sensorDidOutputSynchronizedDepthFrame")
        self.updateTextureFromSampleBuffer(sampleBuffer, object: sceneObjects["Foreground"]!)
        
    }
    
    func sensorDidOutputSynchronizedInfraredFrame(irFrame: STInfraredFrame!, andColorBuffer sampleBuffer: CMSampleBuffer!) {}
    
    
}
