import SwiftUI
import AVFoundation
import ConnectIQ

private let garminAppUUID = UUID(uuidString: "5e59696a-c38b-4afe-b787-9433a22bfae2")!

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        ZStack {
            // Aperçu de la caméra
            CameraPreview(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                Text("En attente de la montre...")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
            cameraManager.setupGarmin()
        }
        .onOpenURL { url in
            let devices = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url) as? [IQDevice] ?? []
            if let device = devices.first {
                cameraManager.setupIQApp(for: device)
            }
        }
    }
}

// Logique de la caméra et de la connexion Garmin
class CameraManager: NSObject, ObservableObject, IQAppMessageDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let ciContext = CIContext()
    private(set) var iqApp: IQApp?
    private var lastPreviewSendTime: TimeInterval = 0

    func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted { self.setupCamera() }
        }
    }

    func setupCamera() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        session.commitConfiguration()
        session.startRunning()
    }

    func setupGarmin() {
        ConnectIQ.sharedInstance().showDeviceSelection()
    }

    func setupIQApp(for device: IQDevice) {
        let app = IQApp(uuid: garminAppUUID, store: garminAppUUID, device: device)
        iqApp = app
        ConnectIQ.sharedInstance().register(forAppMessages: app, delegate: self)
    }

    // IQAppMessageDelegate — déclenché par la montre
    func receivedMessage(_ message: Any, from app: IQApp) {
        if let dict = message as? [String: Any], dict["command"] as? String == "TAKE_PHOTO" {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func sendPreviewToWatch(image: UIImage, app: IQApp) {
        guard let resizedImage = image.resized(to: CGSize(width: 100, height: 100)),
              let jpegData = resizedImage.jpegData(compressionQuality: 0.3) else { return }
        let base64String = jpegData.base64EncodedString()
        ConnectIQ.sharedInstance().sendMessage(
            base64String,
            to: app,
            progress: { sentBytes, totalBytes in
                print("Envoi de l'aperçu: \(sentBytes)/\(totalBytes)")
            },
            completion: { result in
                if result != .success {
                    print("Erreur d'envoi de l'aperçu: \(result.rawValue)")
                }
            }
        )
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("Photo enregistrée !")
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastPreviewSendTime > 1.0,
              let app = iqApp,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastPreviewSendTime = currentTime

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        sendPreviewToWatch(image: uiImage, app: app)
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
