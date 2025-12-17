import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Photo Picker

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    var selectionLimit: Int = 5
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = selectionLimit
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Video Picker

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                guard let url = url else { return }
                
                // Copy to temp location
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: tempURL)
                try? FileManager.default.copyItem(at: url, to: tempURL)
                
                DispatchQueue.main.async {
                    self.parent.selectedVideoURL = tempURL
                }
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .camera
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Video Camera View

struct VideoCameraView: UIViewControllerRepresentable {
    @Binding var capturedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoMaximumDuration = 30 // 30 seconds max
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoCameraView
        
        init(_ parent: VideoCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                // Copy to temp location
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try? FileManager.default.copyItem(at: url, to: tempURL)
                parent.capturedVideoURL = tempURL
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    var contentTypes: [String] = ["public.image", "public.movie"]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes.compactMap { UTType($0) })
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedURL = urls.first
        }
    }
}

// MARK: - Media Picker Sheet

struct MediaPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let onImageSelected: (UIImage) -> Void
    let onVideoSelected: (URL) -> Void
    
    @State private var showingPhotoPicker = false
    @State private var showingVideoPicker = false
    @State private var showingCamera = false
    @State private var showingVideoCamera = false
    @State private var showingFilePicker = false
    
    @State private var selectedImages: [UIImage] = []
    @State private var capturedImage: UIImage?
    @State private var selectedVideoURL: URL?
    @State private var capturedVideoURL: URL?
    @State private var fileURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Photos") {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                    }
                    
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                }
                
                Section("Videos") {
                    Button {
                        showingVideoCamera = true
                    } label: {
                        Label("Record Video", systemImage: "video.fill")
                    }
                    
                    Button {
                        showingVideoPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "film")
                    }
                }
                
                Section("Files") {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Choose from Files", systemImage: "folder.fill")
                    }
                }
            }
            .navigationTitle("Add Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(selectedImages: $selectedImages, selectionLimit: 1)
            }
            .sheet(isPresented: $showingVideoPicker) {
                VideoPicker(selectedVideoURL: $selectedVideoURL)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showingVideoCamera) {
                VideoCameraView(capturedVideoURL: $capturedVideoURL)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(selectedURL: $fileURL)
            }
            .onChange(of: selectedImages) { _, newValue in
                if let image = newValue.last {
                    onImageSelected(image)
                    dismiss()
                }
            }
            .onChange(of: capturedImage) { _, newValue in
                if let image = newValue {
                    onImageSelected(image)
                    dismiss()
                }
            }
            .onChange(of: selectedVideoURL) { _, newValue in
                if let url = newValue {
                    onVideoSelected(url)
                    dismiss()
                }
            }
            .onChange(of: capturedVideoURL) { _, newValue in
                if let url = newValue {
                    onVideoSelected(url)
                    dismiss()
                }
            }
            .onChange(of: fileURL) { _, newValue in
                if let url = newValue {
                    handleFileURL(url)
                }
            }
        }
    }
    
    private func handleFileURL(_ url: URL) {
        // Check if it's an image or video
        let pathExtension = url.pathExtension.lowercased()
        
        if ["jpg", "jpeg", "png", "heic", "heif"].contains(pathExtension) {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                onImageSelected(image)
                dismiss()
            }
        } else if ["mp4", "mov", "m4v"].contains(pathExtension) {
            onVideoSelected(url)
            dismiss()
        }
    }
}

// MARK: - Import UTType
import UniformTypeIdentifiers
