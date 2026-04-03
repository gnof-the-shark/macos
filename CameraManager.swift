import SwiftUI
import AVFoundation
import ConnectIQ

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var statusMessage = "Recherche de la montre..."
    
    private let photoOutput = AVCapturePhotoOutput()
    private var iqApp: IQApp?
    private var lastPreviewTime: TimeInterval = 0
    
    // ID identique à celui du manifest.xml de la montre
    let myAppId = UUID(uuidString: "61626364-6566-6768-6970-717273747576")!

    func setup() {
        checkPermissions()
        setupGarmin()
    }

    private func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted { self.setupCamera() }
        }
    }

    private func setupCamera() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        
        // Ajout du flux vidéo pour l'aperçu sur la montre
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    private func setupGarmin() {
        ConnectIQ.sharedInstance()?.initialize(withUrlScheme: "garmin-connect-iq", delegate: self)
        if let devices = ConnectIQ.sharedInstance()?.getKnownDevices() as? [IQDevice], let device = devices.first {
            registerDevice(device)
        }
    }

    func registerDevice(_ device: IQDevice) {
        iqApp = IQApp(uuid: myAppId, store: nil, device: device)
        ConnectIQ.sharedInstance()?.register(forAppMessages: self, device: device, app: iqApp!)
        DispatchQueue.main.async { self.statusMessage = "Connecté : \(device.friendlyName ?? "Garmin")" }
    }
}

// MARK: - Réception de commandes de la montre
extension CameraManager: IQAppMessageDelegate, IQDeviceEventDelegate {
    func deviceAppMessageReceived(_ message: Any, from device: IQDevice, app: IQApp) {
        if let command = message as? String, command == "TAKE_PHOTO" {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
            
            // Haptique iPhone
            AudioServicesPlaySystemSound(1519) 
        }
    }
    
    func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        if status == .connected { registerDevice(device) }
    }
}

// MARK: - Envoi de l'aperçu (1 fps)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date().timeIntervalSince1970
        // On limite à 1 image par seconde pour ne pas saturer le Bluetooth
        guard now - lastPreviewTime > 1.0, let iqApp = iqApp else { return }
        lastPreviewTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            // Redimensionnement crucial pour la RAM de la vivoactive 3m
            if let smallImage = uiImage.resized(to: CGSize(width: 100, height: 100)) {
                ConnectIQ.sharedInstance()?.sendMessage(smallImage, to: iqApp, from: iqApp.device, progress: nil, completion: nil)
            }
        }
    }
}

// MARK: - Sauvegarde Photo
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
}
