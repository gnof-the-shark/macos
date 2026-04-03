import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    class PreviewView: UIView {
        var session: AVCaptureSession? {
            didSet { previewLayer.session = session }
        }

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            // Safe: layerClass guarantees the backing layer is always AVCaptureVideoPreviewLayer
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("CameraPreview.PreviewView: layerClass must return AVCaptureVideoPreviewLayer")
            }
            return layer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
