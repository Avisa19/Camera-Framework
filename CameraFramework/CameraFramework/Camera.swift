

import UIKit
import AVFoundation

protocol CameraDelegate {
    func stillImageCaptured(with camera: Camera, image: UIImage)
}

class Camera: NSObject {
    
    var delegate: CameraDelegate?
    var position: CameraPosition = .back {
        didSet {
            if self.session.isRunning {
                self.session.stopRunning()
                update()
            }
        }
    }
    
    required override init() {
    
    }

    fileprivate var session = AVCaptureSession()
    fileprivate var discoverySession: AVCaptureDevice.DiscoverySession? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
    }
    
    var videoInput: AVCaptureDeviceInput?
    var videoOutput = AVCaptureVideoDataOutput()
    var photoOutput = AVCapturePhotoOutput()
    
}

extension Camera {
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
    
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return previewLayer
    }
    
    func captureStillImage() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: settings, delegate: self)
        
    }
    
    func update() {
        
        recycleDeviceIO()
        guard let input = getNewInputDevice() else {
            return
        }
        guard self.session.canAddInput(input) else {
            return
        }
        guard self.session.canAddOutput(self.videoOutput) else {
            return
        }
        guard self.session.canAddOutput(self.photoOutput) else {
            return
        }
        self.videoInput = input
        self.session.addInput(input)
        self.session.addOutput(self.videoOutput)
        self.session.addOutput(self.photoOutput)
        self.session.commitConfiguration()
        self.session.startRunning()
    }
}

// MARK: Capture Device Handling
private extension Camera {
    func getNewInputDevice() -> AVCaptureDeviceInput? {
        do {
            guard let device = self.getDevice(with: self.position == .back ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front) else {
                return nil
            }
            let input = try AVCaptureDeviceInput(device: device)
            return input
        } catch {
            print("Error linking device to AVInput!!")
            return nil
        }
    }
    
    func recycleDeviceIO() {
           for oldInput in self.session.inputs {
               self.session.removeInput(oldInput)
           }
           for oldOutput in self.session.outputs {
               self.session.removeOutput(oldOutput)
           }
       }
    
    func getDevice(with positon: AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard let discoverySession = self.discoverySession else {
            return nil
        }
        for device in discoverySession.devices {
            if device.position == positon {
                return device
            }
        }
        return nil
    }
}

// MARK: Still Photo Captured
extension Camera: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let image = photo.normalizedImage(for: self.position) else {
            return
        }
        if let delegate = self.delegate {
            delegate.stillImageCaptured(with: self, image: image)
        }
    }
}

extension AVCapturePhoto {
    func normalizedImage(for cameraPosition: CameraPosition) -> UIImage? {
        guard let cgImage = self.cgImageRepresentation() else {
            return nil
        }
        return UIImage(cgImage: cgImage.takeUnretainedValue(), scale: 1.0, orientation: getImageOrientation(for: cameraPosition))
    }
    
    fileprivate func getImageOrientation(for cameraPosition: CameraPosition) -> UIImage.Orientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return cameraPosition == .back ? .down : .upMirrored
        case .landscapeRight:
            return cameraPosition == .back ? .up : .downMirrored
        case .portraitUpsideDown:
            return cameraPosition == .back ? .left : .rightMirrored
        case .portrait:
            return cameraPosition == .back ? .right : .leftMirrored
        case .unknown:
             return cameraPosition == .back ? .right : .leftMirrored
        case .faceUp:
             return cameraPosition == .back ? .right : .leftMirrored
        case .faceDown:
             return cameraPosition == .back ? .right : .leftMirrored
        @unknown default:
            return cameraPosition == .back ? .right : .leftMirrored
        }
    }
    
}
