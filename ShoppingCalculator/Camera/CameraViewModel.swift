import Foundation
import Photos
import Combine
import SwiftUI
import AVFoundation

class CameraViewModel: ObservableObject {
    
    /// Reference to the CameraManager
    @ObservedObject var cameraManager = CameraManager()
    
    /// Published properties to trigger UI updates
    @Published var isFlashOn = false
    @Published var showAlertError = false
    @Published var showSettingAlert = false
    @Published var isPermissionGranted = false
    @Published var capturedImage: UIImage?
    
    var alertError: AlertError!
    
    /// Reference to the AVCaptureSession
    var session: AVCaptureSession = .init()
    
    /// Cancellable storage for Combine subscribers
    private var cancelables = Set<AnyCancellable>()
    
    init() {
        /// Initialize the session with the cameraManager's session
        session = cameraManager.session
    }
    
    deinit {
        /// Deinitializer to stop capturing when the ViewModel is deallocated
        cameraManager.stopCapturing()
    }
    
    /// Setup Combine bindings for handling publisher's emit values
    func setupBindings() {
        cameraManager.$shouldShowAlertView.sink { [weak self] value in
            /// Update alertError and showAlertError based on cameraManager's state
            self?.alertError = self?.cameraManager.alertError
            self?.showAlertError = value
        }
        .store(in: &cancelables)
        
        cameraManager.$capturedImage.sink { [weak self] image in
            self?.capturedImage = image
        }.store(in: &cancelables)
    }
    
    ///  Call when the capture button tap
    func captureImage() {
        /* -> save photos in your devices gallery
        requestGalleryPermission()
        let permission = checkGalleryPermissionStatus()
        if permission.rawValue != 2 {
            cameraManager.captureImage()
        }
         */
        cameraManager.captureImage() // use photos only for temporary
    }
    
    /// Ask for the permission for photo library access
    /*
    func requestGalleryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                break
            case .denied:
                self.showSettingAlert = true
            default:
                break
            }
        }
    }
    
    func checkGalleryPermissionStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
     */
    
    /// Check for camera device permission
    func checkForDevicePermission() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if videoStatus == .authorized {
            /// If permission granted, configure the camera
            isPermissionGranted = true
            configureCamera()
        } else if videoStatus == .notDetermined {
            /// In case the user had not been asked to grant access we request permission
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                if granted {
                    DispatchQueue.main.async { self.isPermissionGranted = true }
                    self.configureCamera()
                }
            })
        } else if videoStatus == .denied {
            /// If permission denied, show a setting alert
            isPermissionGranted = false
            showSettingAlert = true
        }
    }
    
    /// Configure the camera through the CameraManager to show a live camera preview
    func configureCamera() {
        cameraManager.configureCaptureSession()
    }
    
    func setFocus(point: CGPoint) {
        /// Delegate focus configuration to the CameraManager
        cameraManager.setupFocusOnTap(devicePoint: point)
    }
}

