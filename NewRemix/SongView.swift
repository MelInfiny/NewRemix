//
//  SongView.swift
//  NewRemix
//
//  Created by m1 on 14/01/2025.
//

import SwiftUI

struct SongView: View {
    var fileName: String
    var fileURL: URL
    
    @StateObject private var audioManager = AudioManager()
    @State private var pitch: Float = 0.0
    @State private var selectedEffect: String? = nil

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color.purple, Color.blue]),
                center: .center,
                startRadius: 5,
                endRadius: 500
            )
            .edgesIgnoringSafeArea(.all)


            VStack {
                Spacer()
                
                // Play/Pause button au centre
                Button(action: {
                    if audioManager.isPlaying {
                        audioManager.pause()
                    } else {
                        audioManager.play()
                    }
                }) {
                    Text(audioManager.isPlaying ? "Pause" : "Play")
                        .padding()
                        .font(.title)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(20)
                        .frame(width: 200, height: 150)
                }

                // Progress bar en dessous du bouton Play/Pause
                Slider(value: Binding(
                    get: { audioManager.currentTime },
                    set: { audioManager.seek(to: $0) }),
                       in: 0...audioManager.duration)
                    .accentColor(.white)
                    .background(Color.purple.opacity(0.4))
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 20)
                    .frame(height: 40)

                Spacer()

                // Speed control (avec + et -)
                HStack(spacing: 30) {
                    Button(action: {
                        pitch -= 0.5
                        audioManager.applyEffect(pitch: pitch)
                    }) {
                        Text("-")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(50)
                            .frame(width: 60, height: 60)
                    }

                    Text("Speed: \(pitch, specifier: "%.1f")")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .padding()

                    Button(action: {
                        pitch += 0.5  // Augmenter la vitesse
                        audioManager.applyEffect(pitch: pitch)
                    }) {
                        Text("+")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(50)
                            .frame(width: 60, height: 60)
                    }
                }
                
                Spacer()

                // Effets alignés verticalement
                VStack(spacing: 20) {
                    EffectButton(effectName: "Reverb", isSelected: selectedEffect == "Reverb", action: {
                        selectedEffect = "Reverb"
                        audioManager.applyReverbEffect()
                    })
                    
                    EffectButton(effectName: "Echo", isSelected: selectedEffect == "Echo", action: {
                        selectedEffect = "Echo"
                        audioManager.applyEchoEffect()
                    })
                    
                    EffectButton(effectName: "Flanger", isSelected: selectedEffect == "Flanger", action: {
                        selectedEffect = "Flanger"
                        audioManager.applyFlangerEffect()
                    })
                    
                    EffectButton(effectName: "Distortion", isSelected: selectedEffect == "Distortion", action: {
                        selectedEffect = "Distortion"
                        audioManager.applyDistortionEffect()
                    })
                }
                
                Spacer()

                // Boutons Play/Pause et Stop côte à côte
                HStack(spacing: 30) {
                    Button(action: {
                        audioManager.stop()
                        selectedEffect = nil
                    }) {
                        Text("Stop")
                            .padding()
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(20)
                            .frame(width: 200, height: 80)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            audioManager.loadAudioFile(url: fileURL)
        }
    }
}

struct EffectButton: View {
    var effectName: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(effectName)
                .padding()
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 250, height: 60)
                .background(isSelected ? Color.purple : Color.cyan)
                .cornerRadius(10)
        }
    }
}

#Preview {
    SongView(fileName: "beat-radiance.mp3", fileURL: Bundle.main.url(forResource: "beat-radiance", withExtension: "mp3")!)
}

