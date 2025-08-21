//
//  ContentView.swift
//  AccessRead
//
//  Created by Maliha on 21/8/25.
//

import SwiftUI
import AVFoundation

struct RootView: View {
    var body: some View {
        NavigationStack {
            ReadingAssistantView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: ReadImageView()) {
                            Label("Camera", systemImage: "camera.viewfinder")
                        }
                    }
                }
        }
    }
}

struct ReadingAssistantView: View {
    @State private var userInput: String = ""
    @State private var simplifiedText: String = ""
    @State private var isLoading = false
    @State private var showSimplified = true
    @State private var fontSize: CGFloat = 18
    @FocusState private var isTextEditorFocused: Bool
    @State private var messages: [(role: String, content: String)] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Adaptive Reading Assistant")
                .font(.title2)
                .bold()
                .padding(.top)
            
            // User input text
            TextEditor(text: $userInput)
                .frame(height: 120)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary, lineWidth: 1)).focused($isTextEditorFocused)
                .overlay(alignment: .topLeading) {
                    if userInput.isEmpty {
                        Text("Enter or paste text here...")
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                            .padding(.leading, 5)
                    }
                }.onTapGesture {
                    isTextEditorFocused = true
                } // Ensure focus is set explicitly
            
            
            // Action buttons
            HStack {
                Button(action: {
                    isTextEditorFocused = false
                    simplifyText()
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Simplify")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(userInput.isEmpty || isLoading)
            }
            
            // Toggle original vs simplified
            if !simplifiedText.isEmpty {
                Toggle("Show Simplified", isOn: $showSimplified)
                    .padding(.horizontal)
                
                Text(showSimplified ? simplifiedText : userInput)
                    .font(.system(size: fontSize))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .animation(.easeInOut, value: showSimplified)
                
                // Font size controls
                HStack {
                    Button(action: { fontSize = max(12, fontSize - 2) }) {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .padding(.horizontal)
                    
                    Button(action: { fontSize += 2 }) {
                        Image(systemName: "textformat.size.larger")
                    }
                    .padding(.horizontal)
                }
                
                // Text-to-speech
                Button(action: {
                    let textToRead = showSimplified ? simplifiedText : userInput
                    speak(textToRead)
                }) {
                    Label("Read Aloud", systemImage: "speaker.wave.2")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - API Call
    func simplifyText() {
        guard let url = URL(string: "https://sll19ic417.execute-api.eu-central-1.amazonaws.com/prod/simplify") else {
            simplifiedText = "Invalid API URL."
            return
        }
        
        isLoading = true
        
        messages.append((role: "user", content: userInput))
        //let payload: [String: String] = ["messages": userInput]
        let payload: [String: [[String: String]]] = ["messages": messages.map { ["role": $0.role, "content": $0.content] }]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            simplifiedText = "Failed to encode request."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    simplifiedText = "Error: \(error.localizedDescription)"
                }
                print(simplifiedText)
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    simplifiedText = "No response from server."
                }
                print(simplifiedText)
                return
            }
            
            do {
                if let decoded = try? JSONDecoder().decode(SimplifyResponse.self, from: data) {
                    DispatchQueue.main.async {
                        simplifiedText = decoded.response
                        print(simplifiedText)
                    }
                } else {
                    DispatchQueue.main.async {
                        simplifiedText = String(data: data, encoding: .utf8) ?? "Failed to decode response."
                        print(simplifiedText)
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Text-to-Speech
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        AVSpeechSynthesizer().speak(utterance)
    }
}

struct SimplifyResponse: Decodable {
    let response: String
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
