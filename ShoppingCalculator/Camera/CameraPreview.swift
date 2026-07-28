import Foundation
import SwiftUI
import AVFoundation

/// UIViewRepresentable acts as a bridge to a UI-Kit's UIView
struct CameraPreview: UIViewRepresentable {
    /// manage real-time capture of audio and video
    let session: AVCaptureSession
    
    var onTap: (CGPoint) -> Void /// handle the user's tap actions
    
    /// create and configure a UI-Kit based video preview view
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .clear
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        if let connection = view.videoPreviewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        
        /// Add a tap gesture recognizer to the view
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    /// updates the videoPreviewView
    public func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// UI-Kit based view for displaying the camera preview
    class VideoPreviewView: UIView {
        /// specify the layer class used
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        /// retrieve the AVCaptureVideoPreviewLayer for configuration
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    class Coordinator: NSObject {
        var parent: CameraPreview
        
        init(_ parent: CameraPreview){
            self.parent = parent
        }
        
        @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: sender.view)
            parent.onTap(location)
        }
    }
}
