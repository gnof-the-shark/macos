import UIKit
import Capacitor
import AVFoundation
import ConnectIQ

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let cameraManager = CameraManager() // Ton code est ici

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. On lance la caméra et Garmin
        cameraManager.setup()

        // 2. On crée la couche vidéo (PreviewLayer)
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.videoGravity = .resizeAspectFill
        
        // 3. On l'ajoute au-dessus de tout le reste
        DispatchQueue.main.async {
            if let rootVC = self.window?.rootViewController {
                previewLayer.frame = rootVC.view.bounds
                rootVC.view.layer.insertSublayer(previewLayer, at: 0)
                rootVC.view.backgroundColor = .clear
            }
        }
        
        return true
    }
}

// --- TON CODE CAMERAMANAGER RECOPIÉ ICI ---
class CameraManager: NSObject {
    // Colle ici tout le contenu de ton fichier CameraManager.swift
    // (Sans les lignes "import", car elles sont déjà en haut)
}
