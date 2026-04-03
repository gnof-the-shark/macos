import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        ZStack {
            // La couche de la caméra (le fond)
            CameraPreview()
                .edgesIgnoringSafeArea(.all)
            
            // La couche de texte (par-dessus)
            VStack {
                Text("RemoteCam Garmin")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                
                Spacer()
                
                Text("Connecté à la montre...")
                    .foregroundColor(.green)
                    .padding(.bottom, 50)
            }
        }
    }
}

// Ce bloc permet d'afficher la session de CameraManager dans SwiftUI
struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let cameraManager = (UIApplication.shared.delegate as? AppDelegate)?.cameraManager
        
        if let session = cameraManager?.session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
