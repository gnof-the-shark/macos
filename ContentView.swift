import SwiftUI
import AVFoundation
import ConnectIQ

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
    }
}

// Logique de la caméra et de la connexion Garmin
class CameraManager: NSObject, ObservableObject, IQDeviceEventDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    func checkPermissions() {
        // Code pour demander l'accès à la caméra
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
        session.commitConfiguration()
        session.startRunning()
    }
    
    func setupGarmin() {
        // Initialisation du SDK ConnectIQ pour écouter "TAKE_PHOTO"
        guard let ciq = ConnectIQ.sharedInstance() else { return }
        ciq.showConnectIQDeviceSelection()
    }
    
    // Déclenché par la montre
    func deviceAppMessageReceived(_ message: Any, from device: IQDevice) {
        if let dict = message as? [String: Any], dict["command"] as? String == "TAKE_PHOTO" {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil) // Sauvegarde dans Photos
        print("Photo enregistrée !")
    }
}
