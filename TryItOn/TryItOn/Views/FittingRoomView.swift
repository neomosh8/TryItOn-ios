import SwiftUI

struct FittingRoomView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedItemIndex: Int = 0
    @State private var selectedTemplateIndex: Int = 0
    @State private var isLoading = false
    @State private var currentResult: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var shouldSelectFirstTemplate = false
    @State private var isZoomed = false
    @State private var showingResultDetail = false
    @State private var showingAddItem = false
    @State private var showingAddTemplate = false
    
    var body: some View {
        ZStack {  // Wrap everything in a ZStack to control layering
            VStack {
                // Top slider - User uploaded items
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Add button for items
                        Button(action: {
                            showingAddItem = true
                        }) {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Add Item")
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        
                        if dataManager.items.isEmpty {
                            Text("No items")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        } else {
                            ForEach(Array(dataManager.items.enumerated()), id: \.element.id) { index, item in
                                ItemThumbnail(item: item, isSelected: index == selectedItemIndex)
                                    .onTapGesture {
                                        selectedItemIndex = index
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
                .padding(.vertical)
                
                // Middle canvas for result display
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    } else if let image = currentResult {
                        // The image and controls remain visible but won't be included in the ZStack that gets elevated
                        if !isZoomed {
                            ZStack {
                                // Result image with gesture modifiers
                                ZStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(offset)
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    let delta = value / self.lastScale
                                                    self.lastScale = value
                                                    let newScale = self.scale * delta
                                                    self.scale = min(max(newScale, 0.5), 6.0)
                                                }
                                                .onEnded { _ in
                                                    self.lastScale = 1.0
                                                    if self.scale > 1.1 {
                                                        self.isZoomed = true
                                                    } else if self.scale < 0.9 {
                                                        self.isZoomed = false
                                                    }
                                                }
                                        )
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    if scale > 1.0 {
                                                        self.offset = CGSize(
                                                            width: self.lastOffset.width + value.translation.width,
                                                            height: self.lastOffset.height + value.translation.height
                                                        )
                                                    }
                                                }
                                                .onEnded { _ in
                                                    self.lastOffset = self.offset
                                                }
                                        )
                                        .onTapGesture(count: 2) {
                                            withAnimation(.spring()) {
                                                if isZoomed {
                                                    self.scale = 1.0
                                                    self.offset = .zero
                                                    self.lastOffset = .zero
                                                    self.isZoomed = false
                                                } else {
                                                    self.scale = 2.5
                                                    self.isZoomed = true
                                                }
                                            }
                                        }
                                        .onTapGesture {
                                            // Only navigate to result detail if we're not zoomed
                                            if !isZoomed {
                                                showingResultDetail = true
                                            }
                                        }
                                }
                                .overlay(
                                    // Zoom instructions indicator
                                    VStack {
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.black.opacity(0.6))
                                                    .frame(width: 190, height: 30)
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "hand.draw")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                    
                                                    Text("Pinch to zoom • Double-tap")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.leading, 8)
                                            .padding(.top, 8)
                                            .opacity(0.8)
                                            
                                            Spacer()
                                        }
                                        
                                        Spacer()
                                    }
                                )
                                
                                // Share icon positioned at top right corner
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            saveToGallery()
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        .padding(12)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "tshirt")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text("Select an item and template, then press \"Try It On\"")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding()
                
                // Bottom slider - Templates
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Add button for templates
                        Button(action: {
                            showingAddTemplate = true
                        }) {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Add Template")
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        
                        if dataManager.templates.isEmpty {
                            Text("No templates")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        } else {
                            ForEach(Array(dataManager.templates.enumerated()), id: \.element.id) { index, template in
                                TemplateThumbnail(template: template, isSelected: index == selectedTemplateIndex)
                                    .onTapGesture {
                                        selectedTemplateIndex = index
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
                .padding(.vertical)
                .onChange(of: dataManager.templates.count) { newCount, oldCount in
                    if shouldSelectFirstTemplate && newCount > oldCount {
                        selectedTemplateIndex = 0
                        shouldSelectFirstTemplate = false
                    }
                }
                
                // Action button - "Try It On"
                Button(action: {
                    tryItOn()
                }) {
                    Text("Try It On")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            dataManager.items.isEmpty || dataManager.templates.isEmpty
                                ? Color.gray
                                : Color.blue
                        )
                        .cornerRadius(8)
                }
                .disabled(dataManager.items.isEmpty || dataManager.templates.isEmpty)
                .padding([.horizontal, .bottom])
            }
            
            // Zoomed image overlay that appears on top of everything
            if isZoomed, let image = currentResult {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                self.scale = 1.0
                                self.offset = .zero
                                self.lastOffset = .zero
                                self.isZoomed = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    
                    Spacer()
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / self.lastScale
                                self.lastScale = value
                                let newScale = self.scale * delta
                                self.scale = min(max(newScale, 0.5), 6.0)
                            }
                            .onEnded { _ in
                                self.lastScale = 1.0
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    self.offset = CGSize(
                                        width: self.lastOffset.width + value.translation.width,
                                        height: self.lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                self.lastOffset = self.offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            self.scale = 1.0
                            self.offset = .zero
                            self.lastOffset = .zero
                            self.isZoomed = false
                        }
                    }
                    .transition(.opacity)
            }
        }
        .navigationTitle("Fitting Room")
        .onAppear {
            dataManager.fetchTemplates()
            dataManager.fetchItems()
            dataManager.fetchResults()
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView()
        }
        .sheet(isPresented: $showingAddTemplate) {
            TemplatesView()
        }
        .sheet(isPresented: $showingResultDetail) {
            if let image = currentResult, !dataManager.items.isEmpty {
                FittingRoomResultView(
                    resultImage: image,
                    item: dataManager.items[selectedItemIndex]
                )
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func tryItOn() {
        guard !dataManager.items.isEmpty && !dataManager.templates.isEmpty else { return }
        
        isLoading = true
        
        let selectedItem = dataManager.items[selectedItemIndex]
        let selectedTemplate = dataManager.templates[selectedTemplateIndex]
        
        // Set flag to select first template when templates are updated
        shouldSelectFirstTemplate = true
        
        dataManager.tryOnItemWithTemplate(
            itemId: selectedItem.id,
            templateId: selectedTemplate.id,
            completion: { result in
                isLoading = false
                
                switch result {
                case .success(let image):
                    self.currentResult = image
                    // Reset zoom state when loading a new image
                    self.scale = 1.0
                    self.offset = .zero
                    self.lastOffset = .zero
                    self.isZoomed = false
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    // Reset the flag if there was an error
                    shouldSelectFirstTemplate = false
                }
            }
        )
    }
    
    private func saveToGallery() {
        guard let image = currentResult else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Show a brief success notification
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
}

// Item thumbnail for the top slider (keep the original definition)
struct ItemThumbnail: View {
    let item: Item
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if let url = item.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
            }
            
            Text(item.category.capitalized)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

// Template thumbnail for the bottom slider (keep the original definition)
struct TemplateThumbnail: View {
    let template: Template
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if let url = template.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
            } else {
                Image(systemName: "person.crop.rectangle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
            }
            
            Text(template.category.capitalized)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

// New view for displaying result details when tapping on an image
struct FittingRoomResultView: View {
    let resultImage: UIImage
    let item: Item
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: resultImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding()
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Item Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Category:")
                                .fontWeight(.medium)
                            Text(item.category.capitalized)
                        }
                        .padding(.horizontal)
                        
                        if let url = item.imageURL {
                            Text("Original Item:")
                                .fontWeight(.medium)
                                .padding(.horizontal)
                            
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(8)
                            } placeholder: {
                                ProgressView()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    Button(action: {
                        UIImageWriteToSavedPhotosAlbum(resultImage, nil, nil, nil)
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                    }) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Try-On Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                    }
                }
            }
        }
    }
}
