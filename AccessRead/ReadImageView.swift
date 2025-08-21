//
//  ReadImageView.swift
//  AccessRead
//
//  Created by Maliha on 21/8/25.
//

import SwiftUI
import UIKit

struct ReadImageView: View {
    @State private var isShowingCamera = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            Text("Simplify Text from Photo!")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                
                Button("Read from Image") {
                    // TODO: Send image to backend (Lambda/OpenAI)
                    print("Text recognition logic goes here")
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("Take a photo of an image with text to simply read it.")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Spacer()
            
            Button(action: {
                isShowingCamera = true
            }) {
                Label("Open Camera", systemImage: "camera")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
            }
        }
    }
}

// MARK: - Image Picker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .camera
    var completionHandler: (UIImage) -> Void
    
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
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completionHandler(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
