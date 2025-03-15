import SwiftUI

// Copy the LoginView struct code from the first artifact
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
