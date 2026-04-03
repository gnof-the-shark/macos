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
                // Bouton déclencheur manuel (sans montre)
                Button(action: {
                    cameraManager.takePhoto()
                }) {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .background(Circle().fill(Color.white.opacity(0.3)))
                        .frame(width: 70, height: 70)
                }
                .padding(.bottom, 20)
                // Bouton connexion montre Garmin
                Button("Connecter la montre") {
                    cameraManager.selectGarminDevice()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
            cameraManager.setupGarmin()
        }
        .onOpenURL { url in
            ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url)
            cameraManager.registerForKnownDeviceEvents()
        }
    }
}

// Logique de la caméra et de la connexion Garmin
class CameraManager: NSObject, ObservableObject, IQDeviceEventDelegate, IQAppMessageDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    // UUID de l'app Connect IQ sur la montre (à remplacer par votre propre App ID)
    private let garminAppID = UUID(uuidString: "5e59696a-c38b-4afe-b787-9433a22bfae2")!
    
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
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func setupGarmin() {
        // Enregistrement pour les événements des montres déjà couplées
        registerForKnownDeviceEvents()
    }
    
    func selectGarminDevice() {
        // Ouvre le sélecteur de montre Garmin à la demande de l'utilisateur
        ConnectIQ.sharedInstance().showDeviceSelection()
    }
    
    func registerForKnownDeviceEvents() {
        // Enregistrement pour recevoir les événements et messages de chaque montre connue
        guard let devices = ConnectIQ.sharedInstance().getKnownDevices() as? [IQDevice] else { return }
        for device in devices {
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
            let app = IQApp(id: garminAppID, uuid: garminAppID, device: device)
            ConnectIQ.sharedInstance().register(forAppMessages: app, delegate: self)
        }
    }
    
    // Déclenché par la montre (IQDeviceEventDelegate – ancienne API)
    func deviceAppMessageReceived(_ message: Any, from device: IQDevice) {
        if let dict = message as? [String: Any], dict["command"] as? String == "TAKE_PHOTO" {
            takePhoto()
        }
    }
    
    // Déclenché par la montre (IQAppMessageDelegate)
    func receivedMessage(_ message: Any, fromApp app: IQApp) {
        if let dict = message as? [String: Any], dict["command"] as? String == "TAKE_PHOTO" {
            takePhoto()
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
