//
//  QRCodeViewController.swift
//  KDQRCodeShow
//
//  Created by Kingiol on 15/11/22.
//  Copyright © 2015年 Kingiol. All rights reserved.
//

import UIKit

import AVFoundation

class QRCodeViewController: UIViewController {
    
    var session: AVCaptureSession?
    
    let scanSize = CGSize(width: 200.0, height: 200.0)
    
    var contentW: CGFloat = 0.0
    var contentH: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "QRCodeShow"
        
        let screenSize = UIScreen.mainScreen().bounds.size
        contentW = screenSize.width
        contentH = screenSize.height
        
        setUpCamera()
        setUpQRMask()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        session?.startRunning()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        session?.stopRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: AVCaptureMetadataOutputObjectsDelegate

extension QRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        var stringValue = ""
        if metadataObjects.count > 0 {
            let metaDataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            stringValue = metaDataObject.stringValue
        }
        
        if stringValue.characters.count > 0 {
            session?.stopRunning()
            print("QRCode: \(stringValue)")
        }
    }
    
}

// MARK: Private Methods

extension QRCodeViewController {
    
    func setUpCamera() {
        if checkCameraAvaliable() {
            if checkCameraAuthorise() {
                let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
                var input: AVCaptureDeviceInput;
                do {
                    input = try AVCaptureDeviceInput(device: device)
                } catch let error as NSError {
                    print("error:\(error.localizedDescription)")
                    return
                }
                
                session = AVCaptureSession()
                session!.sessionPreset = AVCaptureSessionPresetHigh
                if session!.canAddInput(input) {
                    session!.addInput(input)
                }
                
                let metaDataOutput = AVCaptureMetadataOutput()
                if session!.canAddOutput(metaDataOutput) {
                    session!.addOutput(metaDataOutput)
                }
                
                let dispatchQueue = dispatch_queue_create("com.kingiol.QRLockQueue", nil)
                metaDataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
                metaDataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
                
                var scanRect = CGRect(x: (contentW-scanSize.width)/2.0, y: (contentH-scanSize.height)/2.0, width: scanSize.width, height: scanSize.height)
                
                scanRect = CGRect(x: scanRect.origin.y/contentH, y: scanRect.origin.x/contentW, width: scanRect.size.height/contentH, height: scanRect.size.width/contentW)
                
                metaDataOutput.rectOfInterest = scanRect
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                
                previewLayer.frame = view.bounds
                view.layer.insertSublayer(previewLayer, atIndex: 0)
            }
        }else {
            print("相机不可用")
        }
    }
    
    func setUpQRMask() {
        let centerRect = CGRect(x: (contentW-scanSize.width)/2.0, y: (contentH-scanSize.height)/2.0, width: scanSize.width, height: scanSize.height)
        
        let path = UIBezierPath(rect: view.bounds)
        let centerPath = UIBezierPath(rect: centerRect)
        path.appendPath(centerPath)
        path.usesEvenOddFillRule = true
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.CGPath
        fillLayer.fillRule = kCAFillRuleEvenOdd
        fillLayer.fillColor = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor
        view.layer.addSublayer(fillLayer)
    }
    
    func checkCameraAvaliable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.Camera);
    }
    
    func checkCameraAuthorise() -> Bool {
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if status == .Restricted || status == .Denied {
            
            let alertActionController = UIAlertController(title: "", message: nil, preferredStyle: .Alert)
            
            let message: String
            
            switch UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch) {
            case .OrderedSame, .OrderedDescending:
                message = "请在设备的\"设置-隐私-相机\"中允许访问相机。"
                alertActionController.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
                alertActionController.addAction(UIAlertAction(title: "确定", style: .Default, handler: { _ -> Void in
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                }))
            case .OrderedAscending:
                // Do Nothing
                message = "请设置允许访问相机。"
                alertActionController.addAction(UIAlertAction(title: "确定", style: UIAlertActionStyle.Cancel, handler: nil))
            }
            
            alertActionController.message = message
            
            presentViewController(alertActionController, animated: true, completion: nil)
            
            return false
        }
        return true
    }
    
}