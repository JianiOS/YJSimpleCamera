//
//  YJSimpleCamera.swift
//
//  Created by Nubia on 16/5/17.
//  Copyright © 2016年 Nubia. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

enum CameraAuthorzation {
    case CameraAuthorzationNotDetermined
    case CameraAuthorzationAvailable
    case CameraAuthorzationUnavailable
}

enum CameraWorkState {
    case CameraWorkAvailable
    case CameraWorkUnavailable
}

enum CameraCaptureImageErrorType {
    case CameraNotWork
    case Other
}

typealias CameraAuthorityRequestHandler = (available:Bool) -> Void

typealias CameraCaptureImageHandler = (image:UIImage?,errorType:CameraCaptureImageErrorType?) -> Void

class YJSimpleCamera: NSObject {
    
    var cameraWorkState:CameraWorkState = .CameraWorkUnavailable
    
    var cameraRunning:Bool {
        return cameraIsRunning
    }
    
    private var cameraIsRunning:Bool = false
    
    private var avsession:AVCaptureSession?
    
    private var cameraLayer:AVCaptureVideoPreviewLayer?
    
    private var avDevice:AVCaptureDevice?
    
    private var avInput:AVCaptureDeviceInput?
    
    private var avOutput:AVCaptureStillImageOutput?
    
    static var outputBufferQueue:dispatch_queue_t?
    
    override init() {
        super.init()
        prepareCamera()
    }
    
    // MARK:Public Function
    func avcaptureSession() -> AVCaptureSession?
    {
        let session = avsession
        return session
    }
    
    func avCameraLayer() -> AVCaptureVideoPreviewLayer? {
        let layer = cameraLayer
        return layer
    }
    
    func startCamera() -> Bool{
        if avsession?.running == false {
            let runCameraSuccess:Bool = prepareRunCamera()
            if runCameraSuccess == true {
                avsession?.startRunning()
            }
            cameraIsRunning = runCameraSuccess
            return runCameraSuccess
        }
        else
        {
            cameraIsRunning = false
            return false
        }
    }
    
    func stopCamera(){
        if avsession?.running  == true{
            avsession?.stopRunning()
            avsession?.removeInput(avInput)
            avsession?.removeOutput(avOutput)
            cameraIsRunning = false
        }
    }
    
    func cameraAvailable() -> CameraAuthorzation
    {
        let authorizationStatus:AVAuthorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        switch authorizationStatus {
        case .NotDetermined:
            return .CameraAuthorzationNotDetermined
        case .Authorized:
            return .CameraAuthorzationAvailable
        case .Denied,.Restricted:
            return .CameraAuthorzationUnavailable
        }
    }
    
    func requestCameraAuthority(completeHandler:CameraAuthorityRequestHandler?)
    {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { (available:Bool) in
            if completeHandler != nil
            {
                completeHandler!(available: available)
            }
        }
    }
    
    func captureImage(completeHandler:CameraCaptureImageHandler?) {
        
        if completeHandler == nil {
            return
        }
        
        if cameraIsRunning == false {
            completeHandler!(image: nil,errorType: .CameraNotWork)
        }
        
        var captureConnection:AVCaptureConnection? = nil
        let connections:[AVCaptureConnection]! = avOutput?.connections as! [AVCaptureConnection]!
        for connection:AVCaptureConnection in connections {
            for port:AVCaptureInputPort in connection.inputPorts as! [AVCaptureInputPort]! {
                if port.mediaType == AVMediaTypeVideo {
                    captureConnection = connection
                    break
                }
            }
            if captureConnection != nil {
                break
            }
        }
        
        if captureConnection == nil {
            completeHandler!(image: nil,errorType: .Other)
        }
        
        avOutput?.captureStillImageAsynchronouslyFromConnection(captureConnection, completionHandler: { (buffer:CMSampleBuffer!, error:NSError!) in
            let imageData:NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            let image:UIImage? = UIImage.init(data: imageData)
            completeHandler!(image: image,errorType: nil)
        })
    }
    
    // MARK:Private Function
    private func prepareCamera() {
        avsession = AVCaptureSession()
        
        let availableCameraDevices:[AVCaptureDevice] = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as![AVCaptureDevice]
        for device:AVCaptureDevice in availableCameraDevices {
            if device.position == .Back {
                avDevice = device
                break
            }
        }
        
        cameraLayer = AVCaptureVideoPreviewLayer.init(session: avsession)
        cameraLayer?.anchorPoint = CGPointZero
    }
    
    private func prepareRunCamera() -> Bool
    {
        if avDevice == nil {
            return false
        }
        
        if avInput == nil {
            setInput(avDevice!)
        }
        
        if avOutput == nil {
            setOutoput(avDevice!)
        }
        
        let canAddInput:Bool! = avsession?.canAddInput(avInput) ?? false
        let canAddOutput:Bool! = avsession?.canAddOutput(avOutput) ?? false
        
        if canAddOutput == true && canAddInput && true {
            avsession?.addInput(avInput)
            avsession?.addOutput(avOutput)
            return true
        }
        else
        {
            return false
        }
    }
    
    private func setInput(device:AVCaptureDevice!) -> Bool
    {
        
        var possibleCameraInput:AVCaptureDeviceInput? = nil
        var canUseInput:Bool = false
        do
        {
            try possibleCameraInput = AVCaptureDeviceInput.init(device: device)
            canUseInput = true
        }
        catch let error as NSError
        {
            print(error)
        }
        
        if canUseInput == true {
            avInput = possibleCameraInput
        }
        
        return canUseInput
    }
    
    private func setOutoput(device:AVCaptureDevice) -> Bool
    {
        let videoOutput:AVCaptureStillImageOutput = AVCaptureStillImageOutput()
        let captureSetting:[String:String] = [AVVideoCodecKey:AVVideoCodecJPEG]
        videoOutput.outputSettings = captureSetting
        avOutput = videoOutput
        return true
    }
    
    private func setCamerBufferQueue() -> Bool
    {
        let bufferQueue:dispatch_queue_t = dispatch_queue_create("com.CameraManager.BufferQueue", DISPATCH_QUEUE_SERIAL)
        CameraManager.outputBufferQueue = bufferQueue
        return true
    }
    
}
