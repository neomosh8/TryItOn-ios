// TryItOn App
// Main App Structure

import SwiftUI
import Combine

@main
struct TryItOnApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
                    .onAppear {
                        dataManager.fetchTemplates()
                        dataManager.fetchResults()
                    }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Authentication and User Management

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username: String = ""
    @Published var isPro: Bool = false
    
    func login(username: String, isPro: Bool) {
        self.username = username
        self.isPro = isPro
        
        // Create user on the server
        let url = URL(string: "\(APIConfig.baseURL)/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userData = ["username": username, "is_pro": isPro]
        request.httpBody = try? JSONEncoder().encode(userData)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Login error: \(error)")
                    return
                }
                
                // Save credentials locally
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(isPro, forKey: "isPro")
                self.isAuthenticated = true
            }
        }.resume()
    }
    
    func checkSavedLogin() {
        if let username = UserDefaults.standard.string(forKey: "username") {
            self.username = username
            self.isPro = UserDefaults.standard.bool(forKey: "isPro")
            self.isAuthenticated = true
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "isPro")
        username = ""
        isPro = false
        isAuthenticated = false
    }
}

// MARK: - Data Models

struct Template: Identifiable, Codable {
    let id: Int
    let filename: String
    let category: String
    
    var imageURL: URL? {
        URL(string: "\(APIConfig.baseURL)/templates/\(filename)")
    }
}

struct TryOnResult: Identifiable, Codable {
    let id: Int
    let filename: String
    let item_category: String
    
    var imageURL: URL? {
        URL(string: "\(APIConfig.baseURL)/images/results/\(filename)")
    }
}

struct TryOnResponseData: Codable {
    let result_ids: [Int]
    let result_urls: [String]
}

enum ItemCategory: String, CaseIterable, Identifiable {
    case accessory = "accessory"
    case shoe = "shoe"
    case clothing = "clothing"
    case glasses = "glasses"
    case general = "general"
    
    var id: String { self.rawValue }
    var displayName: String {
        rawValue.capitalized
    }
}

struct ShopItem {
    let name: String
    let price: String
    let storeURL: URL
}

// MARK: - API Configuration

struct APIConfig {
    static let baseURL = "http://your-api-server:8000" // Replace with your actual API URL
    
    static func authHeader(username: String) -> [String: String] {
        return ["username": username]
    }
}

// MARK: - Data Manager

class DataManager: ObservableObject {
    @Published var templates: [Template] = []
    @Published var results: [TryOnResult] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTemplate: Template?
    @Published var selectedResult: TryOnResult?
    @Published var itemOriginalURL: String?
    @Published var shopItem: ShopItem?
    
    private var cancellables = Set<AnyCancellable>()
    
    @Dependency var authManager: AuthManager
    
    // Dependency injection helper property wrapper
    @propertyWrapper
    struct Dependency {
        var wrappedValue: AuthManager {
            return (UIApplication.shared.delegate as! AppDelegate).authManager
        }
    }
    
    func fetchTemplates() {
        guard !authManager.username.isEmpty else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/templates/")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = APIConfig.authHeader(username: authManager.username)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [Template].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] templates in
                self?.templates = templates
            })
            .store(in: &cancellables)
    }
    
    func fetchResults() {
        guard !authManager.username.isEmpty else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/results/")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = APIConfig.authHeader(username: authManager.username)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [TryOnResult].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] results in
                self?.results = results
            })
            .store(in: &cancellables)
    }
    
    func uploadTemplate(image: UIImage, category: ItemCategory) {
        guard !authManager.username.isEmpty, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/templates/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: authManager.username)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add image data
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        formData.append(imageData)
        
        // Add category
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        formData.append(category.rawValue.data(using: .utf8)!)
        
        // End form data
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: Template.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] template in
                self?.templates.append(template)
            })
            .store(in: &cancellables)
    }
    
    func tryOnFromURL(url: String) {
        guard !authManager.username.isEmpty else { return }
        
        isLoading = true
        let apiURL = URL(string: "\(APIConfig.baseURL)/tryon/url/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: authManager.username)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add URL
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"url\"\r\n\r\n".data(using: .utf8)!)
        formData.append(url.data(using: .utf8)!)
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: TryOnResponseData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] responseData in
                // Store the original URL for reference
                self?.itemOriginalURL = url
                
                // Refresh results to include new items
                self?.fetchResults()
            })
            .store(in: &cancellables)
    }
    
    func tryOnFromImage(image: UIImage) {
        guard !authManager.username.isEmpty, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/tryon/upload/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: authManager.username)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add image data
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"item.jpg\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        formData.append(imageData)
        
        // End form data
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: TryOnResponseData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] _ in
                // Refresh results to include new items
                self?.fetchResults()
            })
            .store(in: &cancellables)
    }
}

// MARK: - Views

// Login View
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username: String = ""
    @State private var isPro: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tshirt.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("TryItOn")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Toggle("Pro Account", isOn: $isPro)
                .padding(.horizontal)
            
            Button(action: {
                authManager.login(username: username, isPro: isPro)
            }) {
                Text("Sign In / Register")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(username.isEmpty)
        }
        .padding()
        .onAppear {
            authManager.checkSavedLogin()
        }
    }
}

// Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView {
            ResultsListView()
                .tabItem {
                    Label("Results", systemImage: "photo.on.rectangle")
                }
            
            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "person.crop.rectangle")
                }
            
            TryOnView()
                .tabItem {
                    Label("Try On", systemImage: "tshirt")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

// Results List View
struct ResultsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if dataManager.results.isEmpty {
                    VStack {
                        Text("No try-on results yet")
                            .font(.headline)
                        Text("Try on some items to see results here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(dataManager.results) { result in
                            ResultRow(result: result)
                                .onTapGesture {
                                    dataManager.selectedResult = result
                                    showingDetail = true
                                }
                        }
                    }
                }
                
                if dataManager.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            }
            .navigationTitle("Try-On Results")
            .refreshable {
                dataManager.fetchResults()
            }
            .sheet(isPresented: $showingDetail) {
                if let result = dataManager.selectedResult {
                    ResultDetailView(result: result)
                }
            }
        }
    }
}

// Result Row
struct ResultRow: View {
    let result: TryOnResult
    
    var body: some View {
        HStack {
            if let url = result.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
            
            VStack(alignment: .leading) {
                Text("Try-On Result")
                    .font(.headline)
                Text("Category: \(result.item_category.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// Result Detail View
struct ResultDetailView: View {
    let result: TryOnResult
    @EnvironmentObject var dataManager: DataManager
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Try-On Result")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .padding()
            
            // Carousel of images
            TabView(selection: $currentIndex) {
                if let url = result.imageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .tag(0)
                }
                
                if let originalURL = dataManager.itemOriginalURL {
                    AsyncImage(url: URL(string: originalURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .tag(1)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .frame(height: 400)
            
            // Item info
            VStack(alignment: .leading, spacing: 10) {
                Text("Item Information")
                    .font(.headline)
                
                if let originalURL = dataManager.itemOriginalURL {
                    Text("Original URL:")
                        .font(.subheadline)
                    
                    Text(originalURL)
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("No original URL available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                // Shop widget placeholder
                VStack(alignment: .leading) {
                    Text("Shop Similar Items")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "cart")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text("Shop Widget Placeholder")
                                .font(.subheadline)
                            Text("Coming soon")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

// Templates View
struct TemplatesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var selectedCategory: ItemCategory = .general
    @State private var isShowingCategoryPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if dataManager.templates.isEmpty {
                    VStack {
                        Text("No templates yet")
                            .font(.headline)
                        Text("Add some templates to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(dataManager.templates) { template in
                            TemplateRow(template: template)
                        }
                    }
                }
                
                if dataManager.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            }
            .navigationTitle("My Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                dataManager.fetchTemplates()
            }
            .sheet(isPresented: $isShowingImagePicker) {
                // Show image picker
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    isShowingCategoryPicker = true
                }
            }
            .actionSheet(isPresented: $isShowingCategoryPicker) {
                ActionSheet(title: Text("Select Template Category"), buttons:
                    ItemCategory.allCases.map { category in
                        .default(Text(category.displayName)) {
                            if let image = selectedImage {
                                dataManager.uploadTemplate(image: image, category: category)
                                selectedImage = nil
                            }
                        }
                    } + [.cancel()]
                )
            }
        }
    }
}

// Template Row
struct TemplateRow: View {
    let template: Template
    
    var body: some View {
        HStack {
            if let url = template.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            } else {
                Image(systemName: "person.crop.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
            
            VStack(alignment: .leading) {
                Text("Template")
                    .font(.headline)
                Text("Category: \(template.category.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// Try On View
struct TryOnView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var urlString = ""
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Try On from Instagram URL")) {
                    TextField("Instagram URL", text: $urlString)
                    
                    Button(action: {
                        if !urlString.isEmpty {
                            dataManager.tryOnFromURL(url: urlString)
                        }
                    }) {
                        Text("Try On from URL")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(urlString.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(urlString.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("Try On from Photo")) {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                
                                Text("Select an Item to Try On")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if selectedImage != nil {
                        Button(action: {
                            if let image = selectedImage {
                                dataManager.tryOnFromImage(image: image)
                                selectedImage = nil
                            }
                        }) {
                            Text("Upload and Try On")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if dataManager.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Processing...")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                
                if let error = dataManager.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Try On Items")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
        }
    }
}

// Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(authManager.username)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Account Type")
                        Spacer()
                        Text(authManager.isPro ? "Pro" : "Standard")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// Image Picker Helper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    @Environment(\.presentationMode) private var presentationMode
    
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
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
