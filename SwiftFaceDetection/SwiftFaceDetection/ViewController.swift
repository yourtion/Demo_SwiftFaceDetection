//
//  ViewController.swift
//  SwiftFaceDetection
//
//  Created by YourtionGuo on 11/11/15.
//  Copyright © 2015 Yourtion. All rights reserved.
//

import UIKit
import AVFoundation

class FaceViewController: UIViewController {
    
    var previewLayer:AVCaptureVideoPreviewLayer!
    var faceRectCALayer:CALayer!
    
    private var currentCameraDevice:AVCaptureDevice?
    
    private var sessionQueue:dispatch_queue_t = dispatch_queue_create("com.yourtion.SwiftFaceDetection.session_access_queue", DISPATCH_QUEUE_SERIAL)
    
    private var session:AVCaptureSession!
    private var backCameraDevice:AVCaptureDevice?
    private var frontCameraDevice:AVCaptureDevice?
    private var metadataOutput:AVCaptureMetadataOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPreset640x480
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
            if device.position == .Back {
                backCameraDevice = device
            }
            else if device.position == .Front {
                frontCameraDevice = device
            }
        }
        let  possibleCameraInput: AnyObject?
        do {
            possibleCameraInput = try AVCaptureDeviceInput(device: frontCameraDevice)
        } catch _ {
            possibleCameraInput = nil
            return
        }
        if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
            if self.session.canAddInput(backCameraInput) {
                self.session.addInput(backCameraInput)
            } else {
                return
            }
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.frame = self.view.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        view.layer.addSublayer(previewLayer)
        
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        
        //初始化人脸框
        faceRectCALayer = CALayer()
        faceRectCALayer.zPosition = 1
        faceRectCALayer.borderColor = UIColor.redColor().CGColor
        faceRectCALayer.borderWidth = 3.0
        faceRectCALayer.zPosition = 20
        self.faceRectCALayer.hidden = true
        self.previewLayer.addSublayer(faceRectCALayer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        if (!session.running) {
            self.session.startRunning()
        }
    }
    
}

extension FaceViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        var faces = Array<(id:Int,frame:CGRect)>()
        
        for metadataObject in metadataObjects as! [AVMetadataObject] {
            if metadataObject.type == AVMetadataObjectTypeFace {
                if let faceObject = metadataObject as? AVMetadataFaceObject {
                    let transformedMetadataObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject)
                    let face:(id: Int, frame: CGRect) = (faceObject.faceID, transformedMetadataObject.bounds)
                    faces.append(face)
                }
            }
        }
        print("FACE",faces)
        
        if (faces.count>0){
            self.setLayerHidden(false)
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.faceRectCALayer.frame = self.findMaxFaceRect(faces)
            });
        } else {
            self.setLayerHidden(true)
        }
    }
    
    func setLayerHidden(hidden:Bool) {
        if (self.faceRectCALayer.hidden != hidden){
            print("hidden: ", hidden)
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.faceRectCALayer.hidden = hidden
            });
        }
    }
    
    func findMaxFaceRect(faces:Array<(id:Int,frame:CGRect)>) -> CGRect {
        if (faces.count == 1) {
            return faces[0].frame
        }
        var maxFace = CGRect.zero
        var maxFace_size = maxFace.size.width + maxFace.size.height
        for face in faces {
            let face_size = face.frame.size.width + face.frame.size.height
            if (face_size > maxFace_size) {
                maxFace = face.frame
                maxFace_size = face_size
            }
        }
        return maxFace
    }
    
}

