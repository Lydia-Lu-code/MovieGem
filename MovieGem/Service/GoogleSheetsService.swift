//
//  GoogleSheetsService.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/13.
//

import Foundation

protocol GoogleSheetsServiceProtocol {
    func fetchData() async throws -> [MovieSheetData]
    func updateSheet(with data: MovieSheetData) async throws
}

class GoogleSheetsService: GoogleSheetsServiceProtocol {
    private let apiEndpoint: String
    
    init(apiEndpoint: String) {
        self.apiEndpoint = apiEndpoint
    }
    
    
    
    func fetchData() async throws -> [MovieSheetData] {
        guard let url = URL(string: apiEndpoint) else {
            print("URL 錯誤：", apiEndpoint)  // 檢查 URL
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        print("API 回應：", String(data: data, encoding: .utf8) ?? "無法解析的資料")  // 檢查 API 回應
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("HTTP 狀態碼錯誤")  // 檢查狀態碼
            throw URLError(.badServerResponse)
        }
        
        return try parseSheetData(data)
    }
    
//    func fetchData() async throws -> [MovieSheetData] {
//        guard let url = URL(string: apiEndpoint) else {
//            throw URLError(.badURL)
//        }
//        
//        let (data, response) = try await URLSession.shared.data(from: url)
//        
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 200 else {
//            throw URLError(.badServerResponse)
//        }
//        
//        return try parseSheetData(data)
//    }
    
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

////
////  GoogleSheetsService.swift
////  MovieGem
////
////  Created by Lydia Lu on 2025/1/13.
////
//
//import Foundation
//
//protocol GoogleSheetsServiceProtocol {
//    func fetchData() async throws -> [MovieSheetData]
//    func updateSheet(with data: MovieSheetData) async throws
//}
//
//class GoogleSheetsService: GoogleSheetsServiceProtocol {
//    private let apiEndpoint: String
//    
//    init(apiEndpoint: String) {
//        self.apiEndpoint = apiEndpoint
//    }
//    
//    func fetchData() async throws -> [MovieSheetData] {
//        guard let url = URL(string: apiEndpoint) else {
//            throw URLError(.badURL)
//        }
//        
//        let (data, response) = try await URLSession.shared.data(from: url)
//        
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 200 else {
//            throw URLError(.badServerResponse)
//        }
//        
//        return try parseSheetData(data)
//    }
//    
//    private func parseSheetData(_ data: Data) throws -> [MovieSheetData] {
//        let decoder = JSONDecoder()
//        return try decoder.decode([MovieSheetData].self, from: data)
//    }
//    
//    func updateSheet(with data: MovieSheetData) async throws {
//        guard let url = URL(string: apiEndpoint) else {
//            throw URLError(.badURL)
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let encoder = JSONEncoder()
//        request.httpBody = try encoder.encode(data)
//        
//        let (_, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 201 else {
//            throw URLError(.badServerResponse)
//        }
//    }
//}
//
//// 加入 MovieSheetData 模型定義
//struct MovieSheetData: Codable {
//    let title: String
//    let rating: Double
//    let genre: String
//    // 根據實際 SheetDB 返回的數據結構添加其他屬性
//    
//    enum CodingKeys: String, CodingKey {
//        case title
//        case rating
//        case genre
//        // 添加其他需要的鍵值對應
//    }
//}
//
//////
//////  GoogleSheetsService.swift
//////  MovieGem
//////
//////  Created by Lydia Lu on 2025/1/13.
//////
////
////import Foundation
////
////protocol GoogleSheetsServiceProtocol {
////    func fetchData() async throws -> [MovieSheetData]
////    func updateSheet(with data: MovieSheetData) async throws
////}
////
////class GoogleSheetsService: GoogleSheetsServiceProtocol {
////    private let spreadsheetId: String
////    private let apiKey: String
////    private let baseURL: String
////    
////    init(spreadsheetId: String, apiKey: String, baseURL: String) {
////        self.spreadsheetId = spreadsheetId
////        self.apiKey = apiKey
////        self.baseURL = baseURL
////    }
////    
////    func fetchData() async throws -> [MovieSheetData] {
////        let baseURL = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1!A:D"
////        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
////            throw URLError(.badURL)
////        }
////        
////        let (data, _) = try await URLSession.shared.data(from: url)
////        // 解析JSON資料
////        return try parseSheetData(data)
////    }
////    
////    private func parseSheetData(_ data: Data) throws -> [MovieSheetData] {
////        // 實作解析邏輯
////        return []
////    }
////    
////    func updateSheet(with data: MovieSheetData) async throws {
////        // 實作更新邏輯
////    }
////}
