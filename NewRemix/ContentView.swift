//
//  ContentView.swift
//  NewRemix
//
//  Created by m1 on 14/01/2025.
//

import SwiftUI
import AVFoundation
import Foundation

import SwiftUI

struct ContentView: View {
    @State private var isImported = false
    @State private var shouldNavigate = false
    @State private var fileName: String? = nil
    @State private var musicUrl: URL? = nil

    var body: some View {
        NavigationStack {
            VStack {
                Button(action: { isImported.toggle() }, label: {
                    Text(fileName ?? "Open ...")
                        .bold()
                        .padding()
                })
                .fileImporter(isPresented: $isImported, allowedContentTypes: [.audio]) { res in
                    do {
                        let url = try res.get()
                        print("Fichier importé : \(url)")
                        self.musicUrl = url
                        self.fileName = url.lastPathComponent
                        self.shouldNavigate = true 
                    } catch {
                        print("Échec de l'importation : \(error.localizedDescription)")
                    }
                }
            }
            .onAppear {
                copyFilesToDocuments()
            }
            .navigationDestination(isPresented: $shouldNavigate) {
                if let fileName = fileName, let musicUrl = musicUrl {
                    SongView(fileName: fileName, fileURL: musicUrl)
                }
            }
        }
    }
    
    func copyFilesToDocuments() {
        // Accès au répertoire Documents de l'application
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Impossible d'accéder au répertoire Documents")
            return
        }

        let audioFiles = [
            ("beat-radiance", "mp3"),
            ("bright-tone", "mp3"),
            ("fresh-pop-alert", "mp3"),
            ("pop-fireworks", "mp3")

        ]

        for (fileName, fileExtension) in audioFiles {
            if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
                let destinationURL = documentsURL.appendingPathComponent("\(fileName).\(fileExtension)")

                do {
                    if !fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.copyItem(at: bundleURL, to: destinationURL)
                        print("Fichier \(fileName).\(fileExtension) copié avec succès dans \(destinationURL)")
                    } else {
                        print("Fichier \(fileName).\(fileExtension) existe déjà.")
                    }
                } catch {
                    print("Erreur lors de la copie du fichier \(fileName): \(error.localizedDescription)")
                }
            } else {
                print("Fichier \(fileName).\(fileExtension) non trouvé dans le bundle.")
            }
        }
    }

}

#Preview {
    ContentView()
}
