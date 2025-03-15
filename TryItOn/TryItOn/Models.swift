//
//  Models.swift
//  TryItOn
//
//  Created by Mojtaba Rabiei on 2025-03-15.
//
import SwiftUI

// Copy the LoginView struct code from the first artifact
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
