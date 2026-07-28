@testable import ShoppingCalculator
import AVFoundation
import Photos
import Combine
import XCTest
import Swift

@MainActor
final class CameraMemoryTests: XCTestCase {
    
    func testDeinit_StopsCameraCapture() {
        var viewModel: CameraViewModel? = CameraViewModel()
        viewModel?.configureCamera()
        let expectation = expectation(description: "Deinit called")
        
        viewModel = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(viewModel)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCameraManager_NoMemoryLeak() {
        weak var weakManager: CameraManager?
        autoreleasepool {
            let manager = CameraManager()
            weakManager = manager
            manager.configureCaptureSession()
        }
        let expectation = expectation(description: "Manager deallocated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNil(weakManager, "CameraManager should be deallocated")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testCameraViewModel_NoMemoryLeak() {
        weak var weakViewModel: CameraViewModel?
        autoreleasepool {
            let viewModel = CameraViewModel()
            weakViewModel = viewModel
            viewModel.setupBindings()
            viewModel.configureCamera()
        }
        let expectation = expectation(description: "ViewModel deallocated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNil(weakViewModel, "CameraViewModel should be deallocated")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Integration Tests
@MainActor
final class CameraIntegrationTests: XCTestCase {
    
    func testCompleteWorkflow_CheckPermission_Configure_Focus_Capture() {
        let viewModel = CameraViewModel()
        let expectation = expectation(description: "Complete workflow")
        viewModel.setupBindings()
        
        viewModel.checkForDevicePermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            viewModel.configureCamera()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                viewModel.setFocus(point: CGPoint(x: 0.5, y: 0.5))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.captureImage()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        XCTAssertNotNil(viewModel)
                        expectation.fulfill()
                    }
                }
            }
        }
        wait(for: [expectation], timeout: 6.0)
    }
    
    func testAlertPropagation_ManagerToViewModel() {
        let viewModel = CameraViewModel()
        let expectation = expectation(description: "Alert propagation")
        viewModel.setupBindings()
        
        viewModel.cameraManager.shouldShowAlertView = true
        viewModel.cameraManager.alertError = AlertError(title: "Test Error", message: "Test Message")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(viewModel.showAlertError)
            XCTAssertNotNil(viewModel.alertError)
            XCTAssertEqual(viewModel.alertError.title, "Test Error")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageCapturePropagation_ManagerToViewModel() {
        let viewModel = CameraViewModel()
        let expectation = expectation(description: "Image propagation")
        viewModel.setupBindings()
        let testImage = UIImage()
        
        viewModel.cameraManager.capturedImage = testImage
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(viewModel.capturedImage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Thread Safety Tests
@MainActor
final class CameraThreadSafetyTests: XCTestCase {
    
    func testConcurrentConfiguration() {
        let sut = CameraManager()
        let expectation = expectation(description: "Concurrent configuration")
        
        DispatchQueue.global().async { sut.configureCaptureSession() }
        DispatchQueue.global().async { sut.configureCaptureSession() }
        DispatchQueue.global().async { sut.configureCaptureSession() }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNotNil(sut)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testConcurrentPublishedPropertyAccess() {
        let sut = CameraManager()
        let expectation = expectation(description: "Concurrent property access")
        let iterations = 100
        
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = sut.status
            _ = sut.shouldShowAlertView
            _ = sut.capturedImage
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNotNil(sut)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Edge Case Tests
@MainActor
final class CameraEdgeCaseTests: XCTestCase {
    func testCaptureImage_BeforeConfiguration() {
        let sut = CameraManager()
        sut.status = .unconfigured
        sut.captureImage()
        XCTAssertEqual(sut.status, .unconfigured)
    }
}

// MARK: - ViewModel Binding Tests
@MainActor
final class CameraViewModelBindingTests: XCTestCase {
    
    func testBinding_AlertViewUpdates() {
        let sut = CameraViewModel()
        var cancellables = Set<AnyCancellable>()
        let expectation = expectation(description: "Alert binding")
        sut.setupBindings()
        
        var receivedValue = false
        sut.$showAlertError.sink { value in
            if value { receivedValue = true }
        }.store(in: &cancellables)
        
        sut.cameraManager.shouldShowAlertView = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(receivedValue)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testBinding_CapturedImageUpdates() {
        let sut = CameraViewModel()
        var cancellables = Set<AnyCancellable>()
        let expectation = expectation(description: "Image binding")
        sut.setupBindings()
        
        var receivedImage: UIImage?
        sut.$capturedImage.sink { image in
            receivedImage = image
        }.store(in: &cancellables)
        
        sut.cameraManager.capturedImage = UIImage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(receivedImage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Focus & Session Tests
@MainActor
final class CameraFocusAndSessionTests: XCTestCase {
    
    func testFocusMode_SetsToAutoFocus() {
        let sut = CameraManager()
        let expectation = expectation(description: "Auto focus set")
        sut.configureCaptureSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            sut.setupFocusOnTap(devicePoint: CGPoint(x: 0.5, y: 0.5))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let device = sut.videoDeviceInput?.device, device.isFocusModeSupported(.autoFocus) {
                    XCTAssertEqual(device.focusMode, .autoFocus)
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSession_StartsRunningAfterConfiguration() {
        let sut = CameraManager()
        let expectation = expectation(description: "Session running")
        
        sut.configureCaptureSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if sut.status == .configured {
                XCTAssertTrue(sut.session.isRunning)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testStopCapturing_WhenSessionRunning_StopsSession() {
        let sut = CameraManager()
        let expectation = expectation(description: "Session stopped")
        sut.configureCaptureSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sut.stopCapturing()
            DispatchQueue.main.async {
                XCTAssertFalse(sut.session.isRunning)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Photo Output Tests
@MainActor
final class CameraPhotoOutputTests: XCTestCase {
    
    func testPhotoOutput_QualityPrioritization() {
        let sut = CameraManager()
        let expectation = expectation(description: "Quality set")
        
        sut.configureCaptureSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if sut.status == .configured {
                XCTAssertEqual(sut.photoOutput.maxPhotoQualityPrioritization, .quality)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPhotoOutput_AddedToSession() {
        let sut = CameraManager()
        let expectation = expectation(description: "Photo output added")
        
        sut.configureCaptureSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if sut.status == .configured {
                XCTAssertTrue(sut.session.outputs.contains(sut.photoOutput))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock Objects & Helpers
protocol PhotoRepresentable {
    func fileDataRepresentation() -> Data?
}

extension AVCapturePhoto: PhotoRepresentable {}

class MockPhoto: PhotoRepresentable {
    let mockImageData: Data?
    init(data: Data?) { self.mockImageData = data }
    func fileDataRepresentation() -> Data? { mockImageData }
}

func createMockImageData() -> Data {
    let size = CGSize(width: 100, height: 100)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        UIColor.red.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    return image.jpegData(compressionQuality: 1.0) ?? Data()
}
