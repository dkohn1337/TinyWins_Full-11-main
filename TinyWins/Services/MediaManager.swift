import Foundation
import UIKit
import AVFoundation

// MARK: - MediaManager
//
// Architecture Note: MediaManager uses the singleton pattern (.shared) intentionally.
//
// This service is a stateless file system wrapper that:
// - Manages a single media directory in the app's Documents folder
// - Performs pure file I/O operations (save, load, delete)
// - Has no mutable state beyond the file system itself
// - Does not depend on or modify app state
//
// Singleton is appropriate here because:
// 1. File operations are inherently global (one file system)
// 2. The service maintains no in-memory state to mock
// 3. Testing can use a separate directory via setUp/tearDown
// 4. DI would add complexity with no testability benefit
//
// If future requirements add state (e.g., caching, upload queues),
// consider migrating to DI via DependencyContainer.

/// Manages storage and retrieval of media files (images and videos) for behavior events.
///
/// This service handles:
/// - Saving images with compression
/// - Saving videos with thumbnail generation
/// - Loading media from disk
/// - Cleaning up orphaned files
///
/// Access via `MediaManager.shared`.
final class MediaManager {
    static let shared = MediaManager()
    
    private let fileManager = FileManager.default
    private let mediaFolderName = "BehaviorMedia"
    
    private init() {
        createMediaDirectoryIfNeeded()
    }
    
    /// URL to the media directory
    private var mediaDirectoryURL: URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            print("Error: Could not access documents directory")
            #endif
            return nil
        }
        return documentsURL.appendingPathComponent(mediaFolderName)
    }
    
    /// Create media directory if it doesn't exist
    private func createMediaDirectoryIfNeeded() {
        guard let mediaDirectoryURL = mediaDirectoryURL else { return }
        if !fileManager.fileExists(atPath: mediaDirectoryURL.path) {
            try? fileManager.createDirectory(at: mediaDirectoryURL, withIntermediateDirectories: true)
        }
    }
    
    /// Save an image and return the MediaAttachment
    func saveImage(_ image: UIImage, quality: CGFloat = 0.8) -> MediaAttachment? {
        guard let mediaDirectoryURL = mediaDirectoryURL else { return nil }
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        do {
            try data.write(to: fileURL)
            return MediaAttachment(
                id: id,
                fileName: fileName,
                mediaType: .image,
                localPath: fileName
            )
        } catch {
            #if DEBUG
            print("Error saving image: \(error)")
            #endif
            return nil
        }
    }
    
    /// Save video from URL and return the MediaAttachment
    func saveVideo(from sourceURL: URL) -> MediaAttachment? {
        guard let mediaDirectoryURL = mediaDirectoryURL else { return nil }
        let id = UUID()
        let fileName = "\(id.uuidString).mp4"
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        
        do {
            // Copy video to our directory
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            try fileManager.copyItem(at: sourceURL, to: fileURL)
            
            // Generate thumbnail
            let thumbnailFileName = "\(id.uuidString)_thumb.jpg"
            let thumbnailPath = generateVideoThumbnail(from: fileURL, fileName: thumbnailFileName)
            
            return MediaAttachment(
                id: id,
                fileName: fileName,
                mediaType: .video,
                localPath: fileName,
                thumbnailPath: thumbnailPath
            )
        } catch {
            #if DEBUG
            print("Error saving video: \(error)")
            #endif
            return nil
        }
    }

    /// Generate thumbnail for video
    private func generateVideoThumbnail(from videoURL: URL, fileName: String) -> String? {
        guard let mediaDirectoryURL = mediaDirectoryURL else { return nil }
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 0.5, preferredTimescale: 600)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)

            let thumbnailURL = mediaDirectoryURL.appendingPathComponent(fileName)
            if let data = thumbnail.jpegData(compressionQuality: 0.7) {
                try data.write(to: thumbnailURL)
                return fileName
            }
        } catch {
            #if DEBUG
            print("Error generating thumbnail: \(error)")
            #endif
        }

        return nil
    }
    
    /// Load image from MediaAttachment
    func loadImage(from attachment: MediaAttachment) -> UIImage? {
        guard let mediaDirectoryURL = mediaDirectoryURL else { return nil }
        let fileURL = mediaDirectoryURL.appendingPathComponent(attachment.localPath)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// Load thumbnail for video
    func loadThumbnail(from attachment: MediaAttachment) -> UIImage? {
        guard let mediaDirectoryURL = mediaDirectoryURL,
              let thumbnailPath = attachment.thumbnailPath else { return nil }
        let fileURL = mediaDirectoryURL.appendingPathComponent(thumbnailPath)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// Get full URL for media file
    func fileURL(for attachment: MediaAttachment) -> URL? {
        mediaDirectoryURL?.appendingPathComponent(attachment.localPath)
    }
    
    /// Delete media file
    func deleteMedia(_ attachment: MediaAttachment) {
        guard let mediaDirectoryURL = mediaDirectoryURL else { return }
        let fileURL = mediaDirectoryURL.appendingPathComponent(attachment.localPath)
        try? fileManager.removeItem(at: fileURL)
        
        // Delete thumbnail if exists
        if let thumbnailPath = attachment.thumbnailPath {
            let thumbnailURL = mediaDirectoryURL.appendingPathComponent(thumbnailPath)
            try? fileManager.removeItem(at: thumbnailURL)
        }
    }
    
    /// Clean up orphaned media files
    func cleanupOrphanedMedia(validAttachments: [MediaAttachment]) {
        guard let mediaDirectoryURL = mediaDirectoryURL else { return }
        let validFileNames = Set(validAttachments.flatMap { attachment -> [String] in
            var names = [attachment.localPath]
            if let thumb = attachment.thumbnailPath {
                names.append(thumb)
            }
            return names
        })

        guard let files = try? fileManager.contentsOfDirectory(atPath: mediaDirectoryURL.path) else { return }
        
        for file in files {
            if !validFileNames.contains(file) {
                let fileURL = mediaDirectoryURL.appendingPathComponent(file)
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
}
