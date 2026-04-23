import Foundation
import AVFoundation
import UIKit
import Observation

@Observable
@MainActor
final class CameraViewModel: NSObject {

    enum Status: Equatable {
        case idle
        case unauthorized
        case configuring
        case running
        case failed(String)
    }

    var status: Status = .idle
    var lastCapturedImage: UIImage?

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "ryzr.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var didConfigure = false
    private var captureContinuation: CheckedContinuation<UIImage, Error>?

    enum CameraError: Error { case notReady, captureFailed }

    func prepareIfNeeded() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await configureAndStart()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { await configureAndStart() } else { status = .unauthorized }
        case .denied, .restricted:
            status = .unauthorized
        @unknown default:
            status = .unauthorized
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func capturePhoto() async throws -> UIImage {
        guard status == .running else { throw CameraError.notReady }
        return try await withCheckedThrowingContinuation { continuation in
            self.captureContinuation = continuation
            sessionQueue.async { [photoOutput] in
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .auto
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Private

    private func configureAndStart() async {
        status = .configuring
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self] in
                guard let self else { cont.resume(); return }
                if !self.didConfigure {
                    self.configureSession()
                    self.didConfigure = true
                }
                if !self.session.isRunning { self.session.startRunning() }
                cont.resume()
            }
        }
        // Verify we got inputs/outputs wired.
        if session.inputs.isEmpty {
            status = .failed("Couldn't open the camera.")
        } else {
            status = .running
        }
    }

    nonisolated private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        let result: Result<UIImage, Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation(), let img = UIImage(data: data) {
            result = .success(img)
        } else {
            result = .failure(CameraError.captureFailed)
        }
        Task { @MainActor in
            switch result {
            case .success(let img):
                self.lastCapturedImage = img
                self.captureContinuation?.resume(returning: img)
            case .failure(let e):
                self.captureContinuation?.resume(throwing: e)
            }
            self.captureContinuation = nil
        }
    }
}
