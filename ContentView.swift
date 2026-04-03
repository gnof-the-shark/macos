import SwiftUI
import AVFoundation

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedPhoto: IdentifiableImage? = nil

    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                // Thumbnail strip of captured photos
                if !cameraManager.capturedPhotos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(cameraManager.capturedPhotos) { item in
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { selectedPhoto = item }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                    .padding(.bottom, 8)
                }

                // Shutter button
                Button(action: { cameraManager.takePhoto() }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 66, height: 66)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
        }
        .sheet(item: $selectedPhoto) { item in
            PhotoDetailView(image: item.image)
        }
    }
}

struct PhotoDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.edgesIgnoringSafeArea(.all)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .edgesIgnoringSafeArea(.all)
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    @Published var capturedPhotos: [IdentifiableImage] = []

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupCamera() }
            }
        default:
            break
        }
    }

    func setupCamera() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        DispatchQueue.main.async {
            self.capturedPhotos.insert(IdentifiableImage(image: image), at: 0)
        }
    }
}
