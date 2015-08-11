//
//  CameraSessionController.swift
//  TestMetalCamera
//
//  Created by emoreau on 2015-08-03.
//  Copyright (c) 2015 emoreau. All rights reserved.
//

import UIKit
import UIKit
import AVFoundation
import CoreMedia
import CoreImage

@objc protocol CameraSessionControllerDelegate {
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
}

class CameraSessionController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    /*----------------------------------------------------------*/
    //MARK: Members
    
    
    var avCaptureSession: AVCaptureSession = AVCaptureSession()
    var sessionQueue: dispatch_queue_t!
    
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDeviceOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    var runtimeErrorHandlingObserver: AnyObject?
    var delegate:CameraSessionControllerDelegate?
    let threadNameConstant = ""
    
    
    
    
    /*----------------------------------------------------------*/
    //MARK: Lifecycle
    override init() {
        super.init();
        
        
       // self.sessionQueue = dispatch_queue_create("CameraSessionController Session", DISPATCH_QUEUE_SERIAL)
       // dispatch_async(self.sessionQueue, {
            self.avCaptureSession.beginConfiguration()
            self.setupColorCamera()
            self.avCaptureSession.commitConfiguration()
       // })
        
    }
    
    
    /*----------------------------------------------------------*/
    //MARK: Class Methods
    class func deviceWithMediaType(mediaType: String, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        var devices: NSArray = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice: AVCaptureDevice = devices.firstObject as! AVCaptureDevice
        
        for object:AnyObject in devices {
            let device = object as! AVCaptureDevice
            if (device.position == position) {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
    
    //--------------------------------------------------------
    //MARK: Instance methods
    
   
    
    
    
    //--------------------------------------------------------
    //MARK: Camera Management
    func queryCameraAuthorizationStatusAndNotifyUserIfNotGranted(){
        
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            // If permission hasn't been granted, notify the user.
            if !granted {
                dispatch_async(dispatch_get_main_queue(), {
                    self.startColorCamera()
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                })
            }
            
            
        });
    }
    
    func startColorCamera(){
        //dispatch_async(self.sessionQueue, {
            var weakSelf: CameraSessionController? = self
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.sessionQueue, queue: nil, usingBlock: {
                (note: NSNotification!) -> Void in
                
                let strongSelf: CameraSessionController = weakSelf!
                
               // dispatch_async(strongSelf.sessionQueue, {
                    strongSelf.avCaptureSession.startRunning()
                //})
            })
            self.avCaptureSession.startRunning()
        //})
    }
    func stopColorCamera(){
//        dispatch_async(self.sessionQueue, {
            self.avCaptureSession.stopRunning()
            NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver!)
 //       })
    }
    
    
    func setColorCameraParametersForInit(){
        var device: AVCaptureDevice = self.videoDeviceInput.device
        var error: NSErrorPointer!
        device.lockForConfiguration(error)
        device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
        device.whiteBalanceMode = AVCaptureWhiteBalanceMode.ContinuousAutoWhiteBalance
        device.unlockForConfiguration()
    }
    func setColorCameraParametersForScanning(){
        var device: AVCaptureDevice = self.videoDeviceInput.device
        var error: NSErrorPointer = NSErrorPointer()
        device.lockForConfiguration(error)
        device.exposureMode = AVCaptureExposureMode.Locked
        device.whiteBalanceMode = AVCaptureWhiteBalanceMode.Locked
        // Force the framerate to 30 FPS, to be in sync with Structure Sensor.
        
        var targetFrameDuration = CMTimeMake(1,15);
        
        // >0 if min duration > desired duration, in which case we need to increase our duration to the minimum
        // or else the camera will throw an exception.
        if(CMTimeCompare(self.videoDeviceInput.device.activeVideoMinFrameDuration, targetFrameDuration)>0)
        {
            // In firmware <= 1.1, we can only support frame sync with 30 fps or 15 fps.
            targetFrameDuration = CMTimeMake(1, 15);
        }
        
        self.videoDeviceInput.device.activeVideoMinFrameDuration = targetFrameDuration
        self.videoDeviceInput.device.activeVideoMaxFrameDuration = targetFrameDuration
        
        
        device.unlockForConfiguration()
        
        
    }
    func setLensPositionWithValue(value:Float, shouldLockVideoDevice lockVideoDevice:Bool){}
    
    func setupColorCamera(){
        self.queryCameraAuthorizationStatusAndNotifyUserIfNotGranted()
        self.addVideoInput()
        self.addVideoOutput()
        self.setColorCameraParametersForScanning()
        
        
    }
    func addVideoInput(){
        
        var error: NSError?
        var videoDevice: AVCaptureDevice = CameraSessionController.deviceWithMediaType(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
        self.videoDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &error) as! AVCaptureDeviceInput;
        if (error == nil) {
            if self.avCaptureSession.canAddInput(self.videoDeviceInput) {
                self.avCaptureSession.addInput(self.videoDeviceInput)
            }
        }
        
        
    }
    func addVideoOutput(){
        
        //TODO: validate video setting
        var settings: [String: Int] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        self.videoDeviceOutput.videoSettings = settings
        self.videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        
        self.videoDeviceOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        
        if self.avCaptureSession.canAddOutput(self.videoDeviceOutput) {
            self.avCaptureSession.addOutput(self.videoDeviceOutput)
        }
    }
    
    
    
    
    /*----------------------------------------------------------*/
    //MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        delegate?.cameraSessionDidOutputSampleBuffer(sampleBuffer, fromConnection: connection)
        
    }
    
    
    
    
    
    
    
    
}
