//
//  AudioManager.swift
//  NewRemix
//
//  Created by m1 on 14/01/2025.
//

import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var playerNode: AVAudioPlayerNode?
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    func loadAudioFile(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
    }
    
    func play() {
        if let audioPlayer = audioPlayer {
            audioPlayer.play()
        } else if let playerNode = playerNode, let audioEngine = audioEngine {
            do {
                try audioEngine.start()
                playerNode.play()
            } catch {
                print("Error starting audio engine: \(error.localizedDescription)")
            }
        }
        isPlaying = true
    }
    
    func pause() {
        if let audioPlayer = audioPlayer {
            audioPlayer.pause()
        } else if let playerNode = playerNode, let audioEngine = audioEngine {
            playerNode.pause()
            audioEngine.pause()
        }
        isPlaying = false
    }
    
    func stop() {
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
        } else if let playerNode = playerNode, let audioEngine = audioEngine {
            playerNode.stop()
            audioEngine.stop()
        }
        isPlaying = false
        audioEngine = nil
        playerNode = nil
    }
    
    
    func seek(to time: TimeInterval) {
        if let audioPlayer = audioPlayer {
            audioPlayer.currentTime = time
        } else if let playerNode = playerNode {
            playerNode.scheduleFile(audioFile!, at: nil, completionHandler: nil)  // Replanifier la lecture à partir du point d'écoute
        }
        currentTime = time
    }
    
    func applyEffect(pitch: Float) {
        applyAudioEffect { audioEngine, playerNode in
            let pitchEffect = AVAudioUnitTimePitch()
            pitchEffect.pitch = pitch
            audioEngine.attach(pitchEffect)
            audioEngine.connect(playerNode, to: pitchEffect, format: nil)
            audioEngine.connect(pitchEffect, to: audioEngine.mainMixerNode, format: nil)
        }
    }
    
    func applyReverseEffect() {
        applyAudioEffect { audioEngine, playerNode in
            guard let audioFile = self.audioFile else { return }
            do {
                let reversedAudioFile = try AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
                try audioFile.read(into: reversedAudioFile)
                reversedAudioFile.reverse()  // Fonction pour inverser les données
                
                audioEngine.attach(playerNode)
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
                
                audioEngine.prepare()
                try audioEngine.start()
                playerNode.scheduleBuffer(reversedAudioFile, at: nil, options: .loops, completionHandler: nil)
                playerNode.play()
            } catch {
                print("Error applying reverse effect: \(error)")
            }
        }
    }
    
    func applyEchoEffect() {
        applyAudioEffect { audioEngine, playerNode in
            let echoEffect = AVAudioUnitDelay()
            echoEffect.delayTime = 0.5 // Delay time in seconds
            echoEffect.feedback = 50 // Feedback level for multiple echoes
            echoEffect.wetDryMix = 50 // Balance between wet (effect) and dry (original) sound
            
            audioEngine.attach(echoEffect)
            audioEngine.connect(playerNode, to: echoEffect, format: nil)
            audioEngine.connect(echoEffect, to: audioEngine.mainMixerNode, format: nil)
        }
    }
    
    func applyReverbEffect() {
        applyAudioEffect { audioEngine, playerNode in
            let reverbEffect = AVAudioUnitReverb()
            reverbEffect.loadFactoryPreset(.largeHall) // Example reverb preset
            reverbEffect.wetDryMix = 50 // Balance between wet (effect) and dry (original) sound
            
            audioEngine.attach(reverbEffect)
            audioEngine.connect(playerNode, to: reverbEffect, format: nil)
            audioEngine.connect(reverbEffect, to: audioEngine.mainMixerNode, format: nil)
        }
    }
    
    func applyFlangerEffect() {
        applyAudioEffect { audioEngine, playerNode in
            let delayEffect = AVAudioUnitDelay()
            delayEffect.delayTime = 0.002
            delayEffect.feedback = 50
            delayEffect.lowPassCutoff = 15000
            delayEffect.wetDryMix = 50
            
            audioEngine.attach(delayEffect)
            audioEngine.connect(playerNode, to: delayEffect, format: nil)
            audioEngine.connect(delayEffect, to: audioEngine.mainMixerNode, format: nil)
        }
    }
    
    // Appliquer l'effet Distorsion
    func applyDistortionEffect() {
        applyAudioEffect { audioEngine, playerNode in
            let distortionEffect = AVAudioUnitDistortion()
            distortionEffect.loadFactoryPreset(.speechRadioTower)  // Exemple de distorsion "speechRadioTower"
            distortionEffect.wetDryMix = 60  // Mélange entre son brut et son traité
            
            audioEngine.attach(distortionEffect)
            audioEngine.connect(playerNode, to: distortionEffect, format: nil)
            audioEngine.connect(distortionEffect, to: audioEngine.mainMixerNode, format: nil)
        }
    }
    
    // Function to apply any audio effect dynamically
    private func applyAudioEffect(effect: (AVAudioEngine, AVAudioPlayerNode) -> Void) {
        guard let audioPlayer = audioPlayer, let url = audioPlayer.url else { return }
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let playerNode = playerNode, let audioEngine = audioEngine else { return }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            self.audioFile = audioFile
            audioEngine.attach(playerNode)
            effect(audioEngine, playerNode)
            
            audioEngine.prepare()
            try audioEngine.start()
            playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
            playerNode.play()
            isPlaying = true
        } catch {
            print("Error applying audio effect: \(error.localizedDescription)")
        }
    }
}
    

// Fonction d'aide pour inverser les données dans le buffer PCM
extension AVAudioPCMBuffer {
    func reverse() {
        guard let channelData = self.floatChannelData else { return }
        let channelCount = Int(self.format.channelCount)
        let frameLength = Int(self.frameLength)

        // Inverser les données de chaque canal
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameLength / 2 {
                let temp = data[frame]
                data[frame] = data[frameLength - frame - 1]
                data[frameLength - frame - 1] = temp
            }
        }
    }
}
