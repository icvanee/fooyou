import SwiftUI
import AVFoundation

// MARK: - Public SwiftUI wrapper

struct BarcodeScannerView: View {
    /// Called once when a barcode is successfully read.
    let onScan: (String) -> Void
    let onCancel: () -> Void

    @StateObject private var coordinator = BarcodeScannerCoordinator()
    @State private var torchOn = false

    var body: some View {
        ZStack {
            CameraPreviewView(coordinator: coordinator)
                .ignoresSafeArea()

            // Viewfinder overlay
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white, lineWidth: 2)
                    .frame(width: 260, height: 180)
                    .shadow(color: .black.opacity(0.4), radius: 8)
                Text("Richt de camera op een barcode")
                    .font(.fooyouCaption())
                    .foregroundStyle(.white)
                    .padding(.top, 12)
                Spacer()
            }

            // Controls
            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    Spacer()
                    Button {
                        torchOn.toggle()
                        coordinator.toggleTorch(on: torchOn)
                    } label: {
                        Image(systemName: torchOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                Spacer()
            }
        }
        .onAppear {
            coordinator.onScan = { barcode in
                onScan(barcode)
            }
            coordinator.startSession()
        }
        .onDisappear {
            coordinator.stopSession()
        }
    }
}

// MARK: - Camera preview (UIViewRepresentable)

private struct CameraPreviewView: UIViewRepresentable {
    let coordinator: BarcodeScannerCoordinator

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        coordinator.previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(coordinator.previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            coordinator.previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - AVFoundation coordinator

@MainActor
final class BarcodeScannerCoordinator: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?

    private let session = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer

    private var hasScanned = false

    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init()
    }

    func startSession() {
        hasScanned = false

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.configureSession()
            await MainActor.run { self.session.startRunning() }
        }
    }

    func stopSession() {
        Task.detached { [weak self] in
            self?.session.stopRunning()
        }
    }

    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    // MARK: - Private

    private func configureSession() async {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized ||
              (await AVCaptureDevice.requestAccess(for: .video)) else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: .main)
        let supported = output.availableMetadataObjectTypes
        let barcodeTypes: [AVMetadataObject.ObjectType] = [
            .ean8, .ean13, .upce, .code39, .code128, .qr, .dataMatrix
        ]
        output.metadataObjectTypes = barcodeTypes.filter { supported.contains($0) }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }

        Task { @MainActor in
            guard !self.hasScanned else { return }
            self.hasScanned = true
            self.session.stopRunning()
            self.onScan?(value)
        }
    }
}
