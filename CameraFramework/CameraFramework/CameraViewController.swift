

import UIKit
import AVFoundation
// from controllr goes to another apps
// from camers NSObject will goes to controller
public protocol CameraControllerDelegate {
    func cancelButtonTapped(controller: CameraViewController)
    func stillImageCaptured(controller: CameraViewController, image: UIImage)
}

public enum CameraPosition {
    case back, front
}

public class CameraViewController: UIViewController {
    fileprivate var camera: Camera?
    // open to any module that its use by
    var previewLayer: AVCaptureVideoPreviewLayer?
    open var delegate: CameraControllerDelegate?
    private var _cancelButton: UIButton?
    // computed property
    var cancelButton: UIButton {
            if let currentButton = _cancelButton {
                return currentButton
            }
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        _cancelButton = button
        return button
    }
    
    private var _shutterButton: UIButton?
    var shutterButton: UIButton {
        if let currentButton = _shutterButton {
            return currentButton
        }
        let button = UIButton()
            // we wanna make sure that we use right bundle Assets
        button.setImage(UIImage(named: "trigger", in: Bundle(for: CameraViewController.self), compatibleWith: nil)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
        _shutterButton = button
        return button
    }
    
    open var position: CameraPosition = .back {
        didSet {
            guard let camera = camera else {
                return
            }
            camera.position = position
        }
    }
  
    // first constructor for your framework
    public init() {
        super.init(nibName: nil, bundle: nil)
        // internaly write camera object and pass it to VC
        let camera = Camera()
        camera.delegate = self
        self.camera = camera
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // we conquire it and create a strong connection
        guard let camera = self.camera else { return }
        createUI()
        camera.update()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateUI(orientation: .unknown)
        updateButtonFrames()
    }
    
    public class func getVersion() -> String? {
        let bundle = Bundle(for: CameraViewController.self)
        guard let info = bundle.infoDictionary else {
            return nil
        }
        guard let versionString = info["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return versionString
    }
    
}

// MARK: User Interface Creation
fileprivate extension CameraViewController {
    
    func createUI() {
        guard let camera = self.camera else {
            return
        }
        guard let previewLayer = camera.getPreviewLayer() else {
            return
        }
        // because wee need it locally for our other classes
        previewLayer.frame = self.view.bounds
        self.previewLayer = previewLayer
        self.view.layer.addSublayer(previewLayer)
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.shutterButton)
    }
    
    func updateUI(orientation: UIInterfaceOrientation) {
        guard let previewLayer = self.previewLayer, let connection = previewLayer.connection else {
            return
        }
        previewLayer.frame = self.view.bounds
        switch orientation {
        case .landscapeLeft:
            connection.videoOrientation = .landscapeLeft
            break
        case .landscapeRight:
            connection.videoOrientation = .landscapeRight
            break
        case .portrait:
            connection.videoOrientation = .portrait
            break
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
            break
        default:
            connection.videoOrientation = .portrait
            break
        }
    }
    
    func updateButtonFrames() {
        self.cancelButton.frame = CGRect(x: self.view.frame.minX + 10, y: self.view.frame.maxY - 50, width: 70, height: 30)
        self.shutterButton.frame = CGRect(x: self.view.frame.midX - 35, y: self.view.frame.maxY - 80, width: 70, height: 70)
    }
    
}
// MARK: UIButton Functions
fileprivate extension CameraViewController {
    @objc func cancelButtonTapped() {
        // we want to make sure that it's not nill
        if let delegate = self.delegate {
            delegate.cancelButtonTapped(controller: self)
        }
    }
    
    @objc func shutterButtonTapped() {
        if let camera = self.camera {
            camera.captureStillImage()
        }
    }
}

// MARK: Camera Delegate Funstions
extension CameraViewController: CameraDelegate {
    func stillImageCaptured(with camera: Camera, image: UIImage) {
        if let delegate = self.delegate {
            delegate.stillImageCaptured(controller: self, image: image)
        }
    }
}

