import SwiftUI
import Combine

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
    
    // Direct reference to AuthManager instead of using property wrapper
    var authManager: AuthManager?
    
    // Helper method to get username from either AuthManager or UserDefaults
    private func getUsername() -> String {
        return authManager?.username ?? UserDefaults.standard.string(forKey: "username") ?? ""
    }
    
    // Helper method to check if user is pro
    private func isPro() -> Bool {
        return authManager?.isPro ?? UserDefaults.standard.bool(forKey: "isPro")
    }
    
    func fetchTemplates() {
        guard !getUsername().isEmpty else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/templates/")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        
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
        guard !getUsername().isEmpty else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/results/")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        
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
    
    // Keeping the original method for backward compatibility
    func uploadTemplate(image: UIImage, category: ItemCategory) {
        uploadTemplate(image: image, category: category) { _, _ in }
    }
    
    func tryOnFromURL(url: String) {
        guard !getUsername().isEmpty else { return }
        
        isLoading = true
        let apiURL = URL(string: "\(APIConfig.baseURL)/tryon/url/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
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
        guard !getUsername().isEmpty, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/tryon/upload/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
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
    
    // Enhanced version with completion handler
    func uploadTemplate(image: UIImage, category: ItemCategory, completion: @escaping (Bool, String) -> Void) {
        guard !getUsername().isEmpty, let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(false, "No username or image data")
            return
        }
        
        print("Starting template upload - Image size: \(imageData.count) bytes")
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/templates/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
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
        
        print("Sending upload request to \(url.absoluteString)")
        print("Username header: \(getUsername())")
        
        // Use a simpler approach for better debugging
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // Check for networking error
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    completion(false, "Upload failed: \(error.localizedDescription)")
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            print("Server error: \(errorStr)")
                            completion(false, "Server error: \(httpResponse.statusCode) - \(errorStr)")
                        } else {
                            completion(false, "Server error: \(httpResponse.statusCode)")
                        }
                        return
                    }
                }
                
                // Parse response
                if let data = data {
                    do {
                        let template = try JSONDecoder().decode(Template.self, from: data)
                        print("Template uploaded successfully: ID \(template.id)")
                        self?.templates.append(template)
                        completion(true, "Template uploaded successfully")
                    } catch {
                        print("Failed to parse response: \(error)")
                        if let responseStr = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseStr)")
                        }
                        completion(false, "Failed to parse response: \(error.localizedDescription)")
                    }
                } else {
                    completion(false, "No data in response")
                }
            }
        }
        
        task.resume()
    }
    
    // Method to test API connectivity
    func testAPIConnection(completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: "\(APIConfig.baseURL)/status")!
        
        print("Testing API connection to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Connection test failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, "Connection failed: \(error.localizedDescription)")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Server response: \(json)")
                        if let dbStatus = json["database"] as? String {
                            DispatchQueue.main.async {
                                completion(true, "Connected! Database: \(dbStatus)")
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(true, "Connected, but unexpected response format")
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(false, "Failed to parse server response")
                        }
                    }
                } catch {
                    print("Parse error: \(error)")
                    DispatchQueue.main.async {
                        completion(false, "Failed to parse response: \(error.localizedDescription)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "No data received from server")
                }
            }
        }.resume()
    }
}
