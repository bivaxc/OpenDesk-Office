import SwiftUI
import VisionKit
import PDFKit

struct DocumentScanner: UIViewControllerRepresentable {
    let onFinished: (Data) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onFinished: onFinished) }
    func makeUIViewController(context: Context) -> UIViewController {
        guard VNDocumentCameraViewController.isSupported else {
            let controller = UIViewController()
            controller.view.backgroundColor = .systemBackground
            return controller
        }
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinished: (Data) -> Void
        init(onFinished: @escaping (Data) -> Void) { self.onFinished = onFinished }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let pdf = PDFDocument()
            for index in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: index)
                if let page = PDFPage(image: image) { pdf.insert(page, at: pdf.pageCount) }
            }
            let data = pdf.dataRepresentation() ?? Data()
            controller.dismiss(animated: true) { self.onFinished(data) }
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}