import Foundation
import Photos
import AVFoundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "CameraManager")

class CameraManager: ObservableObject {
    
    /// represent the camera's status
    enum Status {
        case configured
        case unconfigured
        case unauthorized
        case failed
    }
    
    /// observe changes in the camera's status (main-thread only, for UI)
    @Published var status = Status.unconfigured
    @Published var shouldShowAlertView = false
    @Published var capturedImage: UIImage? = nil
    
    /// internal state for sessionQueue logic (accessed only on sessionQueue)
    private var _internalStatus = Status.unconfigured
    
    private var cameraDelegate: CameraDelegate?
    
    /// AVCaptureSession manage the camera settings and data flow between capture inputs and outputs
    /// It can connect one or more inputs to one or more outputs
    let session = AVCaptureSession()
    
    /// AVCapturePhotoOutput for capturing photos
    let photoOutput = AVCapturePhotoOutput()
    
    /// AVCaptureDeviceInput for handling video input from the camera
    /// Basically provides a bridge the device to the AVCaptureSession
    var videoDeviceInput: AVCaptureDeviceInput?
    
    var alertError: AlertError = AlertError()
    
    /// Serial queue to ensure thread safety when working with the camera
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    /// Method to configure the camera capture sesion
    func configureCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self, self._internalStatus == .unconfigured else { return }
            
            /// Begin session configuration
            self.session.beginConfiguration()
            
            /// Set session preset for high-quality photo capture
            self.session.sessionPreset = .photo
            
            /// Add video input from the device's camera
            self.setupVideoInput()
            
            /// Add the photo output configuration
            self.setupPhotoOutput()
            
            /// Commit session configuration
            self.session.commitConfiguration()
            
            /// Start capturing if everything is configured correctly
            self.startCapturing()
        }
    }
    
    /// Method to set up video input from the camera
    private func setupVideoInput() {
        do {
            /// Get the default wide-angle camera for video capture
            /// AVCaptureDevice is a representation of the hardware device to use
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            guard let camera else {
                logger.error("Camera: Video device is unavailable")
                _internalStatus = .unconfigured
                DispatchQueue.main.async { self.status = .unconfigured }
                session.commitConfiguration()
                return
            }
            
            /// Create an AVCaptureDeviceInput from the camera
            let videoInput = try AVCaptureDeviceInput(device: camera)
            
            /// Add video input to the session if possible
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                videoDeviceInput = videoInput
                _internalStatus = .configured
                DispatchQueue.main.async { self.status = .configured }
            } else {
                logger.error("Camera: Could not add video device input to the session")
                _internalStatus = .unconfigured
                DispatchQueue.main.async { self.status = .unconfigured }
                session.commitConfiguration()
                return
            }
        } catch {
            logger.error("Camera: Could not create video input: \(error)")
            _internalStatus = .failed
            DispatchQueue.main.async { self.status = .failed }
            session.commitConfiguration()
            return
        }
    }
    
    /// Method to configure the photo output settings
    private func setupPhotoOutput() {
        if session.canAddOutput(photoOutput) {
            /// Add the photo output to the session
            session.addOutput(photoOutput)
            
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back){
                let supportedDimensions = device.activeFormat.supportedMaxPhotoDimensions
                
                logger.debug("Camera supported dimensions count: \(supportedDimensions.count)")
                
                if let fitDimensions = supportedDimensions.max(by: {$0.width < $1.width}) {
                    photoOutput.maxPhotoDimensions = fitDimensions
                }
            }
            
            /// Configure photo output settings
            photoOutput.maxPhotoQualityPrioritization = .quality
            
            /// Update the status to indicate successful configuration
            _internalStatus = .configured
            DispatchQueue.main.async { self.status = .configured }
        } else {
            logger.error("Camera: Could not add photo output to the session")
            _internalStatus = .failed
            DispatchQueue.main.async { self.status = .failed }
            session.commitConfiguration()
            return
        }
    }
    
    /// Method to start capturing
    private func startCapturing() {
        if _internalStatus == .configured {
            /// Start ruunning the capture session
            self.session.startRunning()
        } else if _internalStatus == .unconfigured || _internalStatus == .unauthorized {
            DispatchQueue.main.async {
                /// Hnadle errors related to unconfigured or unauthorized states
                self.alertError = AlertError(title: "Camera Error", message: "Camera configuration failed. Either your device camera is not available or missing permission", primaryButtonTitle: "ok", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
                self.shouldShowAlertView = true
            }
        }
    }
    
    /// Method to stop capturing
    func stopCapturing() {
        /// Ensure thread safety using 'sessionQueue'
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            /// Check if the capture sesion is currently running
            if self.session.isRunning {
                /// Stop the capture session and any associated device inputs
                self.session.stopRunning()
            }
        }
    }
    
    func setupFocusOnTap(devicePoint: CGPoint) {
        guard let cameraDevice = self.videoDeviceInput?.device else { return }
        do {
            try cameraDevice.lockForConfiguration()
            
            /// Check if auto-focus is supported and set the focus mode accordingly
            if cameraDevice.isFocusModeSupported(.autoFocus) {
                cameraDevice.focusMode = .autoFocus
                cameraDevice.focusPointOfInterest = devicePoint
            }
            
            /// Set the exposure point and mode for auto-exposure
            cameraDevice.exposurePointOfInterest = devicePoint
            cameraDevice.exposureMode = .autoExpose
            
            /// Enable monitoring for changes in the subject area
            cameraDevice.isSubjectAreaChangeMonitoringEnabled = true
            
            cameraDevice.unlockForConfiguration()
        } catch {
            logger.error("Camera: Failed to configure focus: \(error)")
        }
    }
    
    func captureImage() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            /// Configure photo capture settings
            var photoSettings = AVCapturePhotoSettings()
            
            /// Capture HEIC photos when supported
            /*
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
             */
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back){
                let supportedDimensions = device.activeFormat.supportedMaxPhotoDimensions
                
                logger.debug("Camera supported dimensions count: \(supportedDimensions.count)")
                
                if let fitDimensions = supportedDimensions.max(by: {$0.width < $1.width}) {
                    photoSettings.maxPhotoDimensions = fitDimensions
                }
            }
            
            /// Specify photo quality and preview format
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            
            photoSettings.photoQualityPrioritization = .quality
            
            /// Specify photo quality and preview format
            if let videoConnection = photoOutput.connection(with: .video), videoConnection.isVideoRotationAngleSupported(90) {
                videoConnection.videoRotationAngle = 90
            }
            
            cameraDelegate = CameraDelegate { [weak self] image in
                DispatchQueue.main.async { self?.capturedImage = image }
            }
            
            if let cameraDelegate {
                /// Capture the photo with delegate
                self.photoOutput.capturePhoto(with: photoSettings, delegate: cameraDelegate)
            }
        }
    }
}

class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            logger.error("Camera: Error while capturing photo: \(error)")
            completion(nil)
            return
        }
        
        if let imageData = photo.fileDataRepresentation(), let capturedImage = UIImage(data: imageData) {
            // saveImageToGallery(capturedImage)
            completion(capturedImage)
        } else {
            logger.error("Camera: Image data not available")
        }
    }
    
    /*
    func saveImageToGallery(_ image: UIImage){
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            if success {
                logger.info("Image saved to gallery")
            } else if let error {
                logger.error("Error saving image to gallery: \(error)")
            }
        }
    }
     */
}

public struct AlertError {
    public var title: String = ""
    public var message: String = ""
    public var primaryButtonTitle = "Accept"
    public var secondaryButtonTitle: String?
    public var primaryAction: (() -> ())?
    public var secondaryAction: (() -> ())?
    
    public init(title: String = "", message: String = "", primaryButtonTitle: String = "Accept", secondaryButtonTitle: String? = nil, primaryAction: (() -> ())? = nil, secondaryAction: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryAction = secondaryAction
    }
}

