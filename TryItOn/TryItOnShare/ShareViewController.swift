// Share Extension
// This file should be added to a new Share Extension target in your iOS project

import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {
    
    private var urlString: String?
    private var selectedCategory: String = "general"
    private var imageData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title and placeholder text
        title = "Share to TryItOn"
        self.placeholder = "Try on this item..."
        
        // Add category selection button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Category",
            style: .plain,
            target: self,
            action: #selector(selectCategory)
        )
        
        // Check what kind of content we're sharing
        extractSharedContent()
    }
    
    @objc func selectCategory() {
        let alertController = UIAlertController(
            title: "Select Category",
            message: "Choose a category for this item",
            preferredStyle: .actionSheet
        )
        
        // Add actions for each category
        let categories = ["accessory", "shoe", "clothing", "glasses", "general"]
        for category in categories {
            let action = UIAlertAction(title: category.capitalized, style: .default) { [weak self] _ in
                self?.selectedCategory = category
            }
            alertController.addAction(action)
        }
        
        // Add cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Present action sheet
        present(alertController, animated: true)
    }
    
    private func extractSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        
        for extensionItem in extensionItems {
            guard let itemProviders = extensionItem.attachments else { continue }
            
            for itemProvider in itemProviders {
                // Check for URL
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (url, error) in
                        if let shareURL = url as? URL {
                            DispatchQueue.main.async {
                                self?.urlString = shareURL.absoluteString
                            }
                        }
                    }
                }
                
                // Check for image
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { [weak self] (data, error) in
                        guard error == nil else { return }
                        
                        if let url = data as? URL {
                            // Load image from URL
                            if let imageData = try? Data(contentsOf: url) {
                                DispatchQueue.main.async {
                                    self?.imageData = imageData
                                }
                            }
                        } else if let image = data as? UIImage, let jpegData = image.jpegData(compressionQuality: 0.8) {
                            // Direct image data
                            DispatchQueue.main.async {
                                self?.imageData = jpegData
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func didSelectPost() {
        // This is called when the user selects Post
        
        // Get username from app group shared storage
        let userDefaults = UserDefaults(suiteName: "group.com.yourdomain.TryItOn")
        guard let username = userDefaults?.string(forKey: "username") else {
            let alert = UIAlertController(
                title: "Not Logged In",
                message: "Please login to TryItOn app first",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
            present(alert, animated: true)
            return
        }
        
        // Determine if we're processing a URL or an image
        if let urlString = urlString, urlString.contains("instagram.com") || urlString.contains("tiktok.com") {
            // Process URL (Instagram or TikTok)
            sendURLToApp(url: urlString, username: username)
        } else if let imageData = imageData {
            // Process image data as template (for selfies)
            sendImageToApp(imageData: imageData, username: username, isTemplate: true)
        } else {
            // Show error
            let alert = UIAlertController(
                title: "Error",
                message: "Unsupported content type",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
            present(alert, animated: true)
            return
        }
    }
    
    private func sendURLToApp(url: String, username: String) {
        // Base URL of your API
        let baseURL = "http://your-api-server:8000" // Replace with your actual API URL
        let apiURL = URL(string: "\(baseURL)/tryon/url/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue(username, forHTTPHeaderField: "username")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add URL
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"url\"\r\n\r\n".data(using: .utf8)!)
        formData.append(url.data(using: .utf8)!)
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        // Create and start the task
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    // Show error
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    })
                    self?.present(alert, animated: true)
                    return
                }
                
                // Success - close extension
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
        
        task.resume()
    }
    
    private func sendImageToApp(imageData: Data, username: String, isTemplate: Bool) {
        // Base URL of your API
        let baseURL = "http://your-api-server:8000" // Replace with your actual API URL
        
        // Determine which endpoint to use
        let endpoint = isTemplate ? "/templates/" : "/tryon/upload/"
        let apiURL = URL(string: "\(baseURL)\(endpoint)")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue(username, forHTTPHeaderField: "username")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add image data
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        formData.append(imageData)
        
        // If this is a template, add category
        if isTemplate {
            formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            formData.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
            formData.append(selectedCategory.data(using: .utf8)!)
        }
        
        // End form data
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        // Create and start the task
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    // Show error
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    })
                    self?.present(alert, animated: true)
                    return
                }
                
                // Success - close extension
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
        
        task.resume()
    }
    
    override func configurationItems() -> [Any]! {
        // Add configuration settings here
        return []
    }
}
