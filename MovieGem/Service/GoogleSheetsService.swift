//
//  GoogleSheetsService.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/13.
//

import Foundation
import UIKit
import Combine

protocol GoogleSheetsServiceProtocol {
    func fetchData() async throws -> [MovieSheetData]
    func updateSheet(with data: MovieSheetData) async throws
}

struct SheetDBConfig {
    // SheetDB API endpoint
    static let apiEndpoint = "https://sheetdb.io/api/v1/gwog7qdzdkusm"
    
    // 如果需要添加其他設定，可以在這裡擴充
    static let timeout: TimeInterval = 30.0
    static let maxRetries = 3
}

class GoogleSheetsService: GoogleSheetsServiceProtocol {
    private let apiEndpoint: String
    
    init(apiEndpoint: String) {
        self.apiEndpoint = apiEndpoint
    }
    
    func fetchData() async throws -> [MovieSheetData] {
        guard let url = URL(string: apiEndpoint) else {
            print("❌ URL 錯誤：\(apiEndpoint)")
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 詳細日誌
            print("🌐 API 端點: \(apiEndpoint)")
            print("🔍 回應數據: \(String(data: data, encoding: .utf8) ?? "無法解析")")
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ HTTP 響應錯誤")
                throw URLError(.badServerResponse)
            }
            
            return try parseSheetData(data)
        } catch {
            print("❌ 網路請求錯誤: \(error)")
            throw error
        }
    }
    
    private func parseSheetData(_ data: Data) throws -> [MovieSheetData] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([MovieSheetData].self, from: data)
    }
    
    func updateSheet(with data: MovieSheetData) async throws {
        guard let url = URL(string: apiEndpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(data)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
}

