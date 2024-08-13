//
//  ContentView.swift
//  VideoToAudio
//
//  Created by Mikami Kirigaya on 2024-08-13.
//

import SwiftUI

struct ContentView: View {
    @State private var showSavePanel = false
    @State private var outputURL: URL?
    
    var body: some View {
        VStack {
            Text("Drag and drop a video file here")
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                    return true
                }
            
            if let outputURL = outputURL {
                Text("Saved to: \(outputURL.path)")
                    .padding()
            }
        }
        .frame(width: 400, height: 200)
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
        savePanel.allowedFileTypes = ["aac"]
        savePanel.nameFieldStringValue = videoURL.deletingPathExtension().lastPathComponent
        savePanel.begin { response in
            if response == .OK, let selectedURL = savePanel.url {
                outputURL = selectedURL
                extractAudio(from: videoURL, to: selectedURL)
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
        
        task.arguments = ["-i", videoURL.path, "-vn", "-acodec", "copy", outputURL.path]
        
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
