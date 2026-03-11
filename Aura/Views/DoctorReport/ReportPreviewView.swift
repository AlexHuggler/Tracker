import SwiftUI
import PDFKit

struct ReportPreviewView: View {
    let pdfData: Data
    let patientName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFPreviewRepresentable(data: pdfData)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Report Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: PDFDocument(data: pdfData) ?? PDFDocument(),
                            preview: SharePreview(
                                "Symptom Report — \(patientName)",
                                image: Image(systemName: "doc.text")
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

struct PDFPreviewRepresentable: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(data: data)
        }
    }
}
