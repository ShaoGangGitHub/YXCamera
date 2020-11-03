//
//  YXCamera.swift
//  YXToolSDK
//
//  Created by shg on 2020/11/1.
//

import UIKit

@objc public class YXCamera: UIView {

    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession.init()
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        return session
    }()
    
    private lazy var capLayer:AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer.init(session: self.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = self.bounds
        return layer
    }()
    
    private var device:AVCaptureDevice?
    
    private lazy var capInput:AVCaptureDeviceInput? = {
        if let device = AVCaptureDevice.default( .builtInWideAngleCamera, for: .video, position: .back) {
            do {
                try device.lockForConfiguration()
            } catch  {
                return nil
            }
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            device.unlockForConfiguration()
            self.device = device
            var input:AVCaptureDeviceInput?
            do {
                try input = AVCaptureDeviceInput.init(device: device)
            } catch {
                print(error)
            }
            return input
        }
        return nil
    }()
    
    private lazy var capOutput:AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput.init()
        return output
    }()
    
    private lazy var delegate:YXCameraDelgate = {
        let delegate:YXCameraDelgate = YXCameraDelgate.init()
        return delegate
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        if self.deviceStatus() != .authorized {
            print("未授权")
            return
        }
        if self.capInput == nil {
            print("捕捉设备输入异常")
            return
        }
        self.layer.addSublayer(self.capLayer)
        if self.session.canAddInput(self.capInput!) {
            self.session.addInput(self.capInput!)
        }
        if self.session.canAddOutput(self.capOutput) {
            self.session.addOutput(self.capOutput)
        }
        self.session.startRunning()
        
    }
    
    /// 设备权限
    /// - Returns: 授权状态
    @objc public func deviceStatus() -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status
    }
    
    /// 开始拍照
    @objc public func start(backImage:@escaping((_:UIImage) -> Void)) {
        self.delegate.backimage = backImage
        let setting = AVCapturePhotoSettings.init(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])
        if self.device!.hasFlash && self.device!.isFlashAvailable {
            if self.capOutput.supportedFlashModes.contains(.auto) {
                setting.flashMode = .auto
            }
        }
        self.capOutput.capturePhoto(with: setting, delegate: self.delegate)
    }
    
    /// 切换前后摄像头
    /// - Parameter position: .front 前置  .back 后置
    /// - Returns: 设备捕捉输入
    @objc public func changeCam(position:AVCaptureDevice.Position) {
        if self.device!.position == position {
            return
        }
        if let device = AVCaptureDevice.default( .builtInWideAngleCamera, for: .video, position: position) {
            do {
                try device.lockForConfiguration()
            } catch  {
                print("异常",error)
                return
            }
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            device.unlockForConfiguration()
            self.device = device
            var input:AVCaptureDeviceInput?
            do {
                try input = AVCaptureDeviceInput.init(device: device)
            } catch {
                print("异常",error)
                return
            }
            if input != nil {
                //添加到session
                if self.session.inputs.contains(self.capInput!) {
                    self.session.removeInput(self.capInput!)
                    self.capInput = nil
                }
                self.capInput = input
                if self.session.canAddInput(self.capInput!) {
                    self.session.addInput(self.capInput!)
                }
                
                //添加切换动画
                let animation:CATransition = CATransition.init()
                animation.duration = 0.5
                animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
                animation.type = CATransitionType(rawValue: "cameraIrisHollowOpen")
                if position == .front {
                    animation.subtype = .fromRight
                } else if position == .back {
                    animation.subtype = .fromLeft
                }
                self.capLayer.removeAllAnimations()
                self.capLayer.add(animation, forKey: nil)
                
            } else {
                print("摄像头切换失败")
            }
        }
    }
    
    /// 打开手电筒
    /// - Parameter torchMode: public enum TorchMode : Int { case off = 0 case on = 1 case auto = 2 }
    @objc public func openTorch(_ torchMode:AVCaptureDevice.TorchMode) {
        if self.device!.hasTorch && self.device!.isTorchAvailable {
            if self.device!.isTorchModeSupported(torchMode) {
                do {
                    try self.device!.lockForConfiguration()
                } catch {
                    print("手电筒打开异常",error)
                    return
                }
                self.device!.torchMode = torchMode
                self.device!.unlockForConfiguration()
            }
        } else {
            print("手电筒不可用")
        }
    }
    
    /// 判断手电筒状态
    /// - Returns: true 打开状态  false 关闭状态
    @objc public func isTorchActive() -> Bool {
        return self.device!.isTorchActive
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: -- 处理AVCapturePhotoCaptureDelegate代理回调
class YXCameraDelgate: NSObject ,AVCapturePhotoCaptureDelegate {
    
    
    var backimage:((_:UIImage) -> ())?
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        guard let image = UIImage.init(data: data) else { return }
        if self.backimage != nil {
            self.backimage!(image)
        }
    }
}

