//
//  GoogleSheetsService.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/13.
//

import Foundation
import UIKit
import Combine

struct BookingRecord: Codable {
    let date: String
    let movieName: String
    let showDate: String
    let showTime: String
    let numberOfTickets: String
    let ticketType: String
    let seats: String
    let totalAmount: String
    
    private enum CodingKeys: String, CodingKey {
        case date = "訂票日期"
        case movieName = "電影名稱"
        case showDate = "場次日期"
        case showTime = "場次時間"
        case numberOfTickets = "人數"
        case ticketType = "票種"
        case seats = "座位"
        case totalAmount = "總金額"
    }
}

protocol GoogleSheetsServiceProtocol {
    func fetchData(for date: Date?) async throws -> [MovieSheetData]
    func updateSheet(with data: MovieSheetData) async throws
    func fetchBookingRecords(for date: String, completion: @escaping (Result<[BookingRecord], Error>) -> Void)
}

struct SheetDBConfig {
    // SheetDB API endpoint
    static let apiEndpoint = "https://sheetdb.io/api/v1/gwog7qdzdkusm"
    
    // 如果需要添加其他設定，可以在這裡擴充
    static let timeout: TimeInterval = 30.0
    static let maxRetries = 3
    static let sheetName = "MovieBookingData"
}

class GoogleSheetsService: GoogleSheetsServiceProtocol {
    private let apiEndpoint: String
    private let session: URLSession
    
    init(apiEndpoint: String = SheetDBConfig.apiEndpoint) {
        self.apiEndpoint = apiEndpoint
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
    }
    
    // 實現 fetchData 方法
    func fetchData(for date: Date?) async throws -> [MovieSheetData] {
        return try await performFetch(for: date)
    }
    
    private func performFetch(for date: Date?) async throws -> [MovieSheetData] {
        var urlComponents = URLComponents(string: apiEndpoint)
        
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            urlComponents?.queryItems = [
                URLQueryItem(name: "sheet", value: "﻿MovieBookingData"),
                URLQueryItem(name: "訂票日期", value: dateString)
            ]
        }
        
        guard let url = urlComponents?.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([MovieSheetData].self, from: data)
    }
    
    
    
    
    func fetchBookingRecords(for date: String, completion: @escaping (Result<[BookingRecord], Error>) -> Void) {
        
        print("🌐 API 請求網址：\(apiEndpoint)")
        print("📅 請求日期：\(date)")
        
        guard var components = URLComponents(string: apiEndpoint) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        // 只使用一個日期查詢參數
        components.queryItems = [
            URLQueryItem(name: "sheet", value: "MovieBookingData"),
            URLQueryItem(name: "訂票日期", value: date)  // 只保留一個日期參數
        ]
        
        guard let url = components.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // 詳細的錯誤處理
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.success([]))
                return
            }
            
            do {
                let jsonString = String(data: data, encoding: .utf8) ?? "無法解碼"
                
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let records = try decoder.decode([BookingRecord].self, from: data)
                
                completion(.success(records))
                
            } catch {
                completion(.failure(error))
            }
        }
        print("📍 完整 URL：\(url)")
        
        task.resume()
    }

    // 輔助方法：解析記錄的替代方案
    private func parseBookingRecords(from data: Data) throws -> [BookingRecord] {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try decoder.decode([BookingRecord].self, from: data)
    }
    
    
    // 已有的 updateSheet 方法
    func updateSheet(with data: MovieSheetData) async throws {
        guard let url = URL(string: apiEndpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(data)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
}


