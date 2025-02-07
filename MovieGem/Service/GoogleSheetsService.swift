import Foundation
import Combine


protocol MovieBookingDataService {
//    func fetchMovieBookings(for date: String) async throws -> [BookingRecord]
    func fetchMovieBookings() async throws -> [BookingRecord]
    func addBooking(_ booking: BookingRecord) async throws
    func updateBooking(_ booking: BookingRecord) async throws
    func deleteBooking(_ date: String, movieName: String) async throws
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

//class GoogleSheetsService: GoogleSheetsServiceProtocol {
class GoogleSheetsService: GoogleSheetsServiceProtocol, MovieBookingDataService {
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
    
    // 新增 MovieBookingDataService 協定要求的方法
    func fetchMovieBookings() async throws -> [BookingRecord] {
        return try await withCheckedThrowingContinuation { continuation in
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            let dateString = dateFormatter.string(from: currentDate)
            
            fetchBookingRecords(for: dateString) { result in
                switch result {
                case .success(let records):
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func addBooking(_ booking: BookingRecord) async throws {
        // 實作新增預訂的邏輯
        print("新增預訂紀錄:", booking)
    }
    
    func updateBooking(_ booking: BookingRecord) async throws {
        // 實作更新預訂的邏輯
        print("更新預訂紀錄:", booking)
    }
    
    func deleteBooking(_ date: String, movieName: String) async throws {
        // 實作刪除預訂的邏輯
        print("刪除預訂紀錄，日期:", date, "電影:", movieName)
    }
    

    
    
}


