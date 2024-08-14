//
//  ContentView.swift
//  VideoToAudio
//
//  Created by Mikami Kirigaya on 2024-08-13.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showSavePanel = false
    @State private var outputURL: URL?
    @State private var isConverting = false
    @State private var isDragging = false
    
    var body: some View {
        VStack {
                    if isConverting {
                        Text("Converting...")
                            .font(.headline)
                            .padding()
                    } else {
                        VStack {
                            Text("Drag and drop a video file here")
                                .font(.title2)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                                .background(isDragging ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isDragging ? Color.blue : Color.gray, lineWidth: 2)
                                )
                                .shadow(color: isDragging ? Color.blue.opacity(0.5) : Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .onDrop(of: ["public.file-url"], isTargeted: $isDragging) { providers in
                                    handleDrop(providers: providers)
                                    return true
                                }
                            
                            
                        }
                        .padding()
                    }
                    
                    if let outputURL = outputURL {
                        Text("Saved to: \(outputURL.path)")
                            .padding()
                    }
                }
                .frame(width: 400, height: 300)
            }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            promptForSaveLocation(videoURL: url)
                        }
                    }
                }
            }
        }
    }
    
    private func promptForSaveLocation(videoURL: URL) {
        let savePanel = NSSavePanel()
        
        // Define allowed content types based on UTType
        savePanel.allowedContentTypes = [
            UTType(filenameExtension: "m4a")!,
            UTType(filenameExtension: "flac")!,
            UTType(filenameExtension: "mp3")!,
            UTType(filenameExtension: "wav")!,
            UTType(filenameExtension: "wma")!,
            UTType(filenameExtension: "aac")!
        ]
        
        savePanel.nameFieldStringValue = videoURL.deletingPathExtension().lastPathComponent
        
        // Display the save panel in the main window
        if let window = NSApplication.shared.windows.first {
            savePanel.beginSheetModal(for: window) { response in
                if response == .OK, let selectedURL = savePanel.url {
                    outputURL = selectedURL
                    convertAudioInBackground(videoURL: videoURL, outputURL: selectedURL)
                }
            }
        } else {
            // Fallback to regular save panel if the main window is not found
            savePanel.begin { response in
                if response == .OK, let selectedURL = savePanel.url {
                    outputURL = selectedURL
                    convertAudioInBackground(videoURL: videoURL, outputURL: selectedURL)
                }
            }
        }
    }
    
    private func convertAudioInBackground(videoURL: URL, outputURL: URL) {
        isConverting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            extractAudio(from: videoURL, to: outputURL)
            
            DispatchQueue.main.async {
                isConverting = false
            }
        }
    }
    
    private func extractAudio(from videoURL: URL, to outputURL: URL) {
        let task = Process()
        
        // Get the path to the bundled FFmpeg executable
        if let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) {
            task.launchPath = ffmpegPath
        } else {
            print("FFmpeg not found in the app bundle.")
            return
        }
        
        // Determine the audio codec based on the file extension
        let fileExtension = outputURL.pathExtension.lowercased()
        let audioCodec: String
        
        switch fileExtension {
        case "m4a":
            audioCodec = "aac"
        case "flac":
            audioCodec = "flac"
        case "mp3":
            audioCodec = "libmp3lame"
        case "wav":
            audioCodec = "pcm_s16le"
        case "wma":
            audioCodec = "wmav2"
        case "aac":
            audioCodec = "aac"
        default:
            print("Unsupported file format: \(fileExtension)")
            return
        }
        
        task.arguments = ["-i", videoURL.path, "-vn", "-acodec", audioCodec, outputURL.path]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Error running FFmpeg: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
