import Foundation

protocol MovieBookingDataService {
    func fetchBookingRecords(for date: String) async throws -> [BookingRecord]
    func fetchMovieBookings() async throws -> [BookingRecord]
}

class GoogleSheetsService: MovieBookingDataService {
    private let apiEndpoint = "https://sheetdb.io/api/v1/gwog7qdzdkusm"
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
    }
    
    func fetchBookingRecords(for date: String) async throws -> [BookingRecord] {
        guard var components = URLComponents(string: apiEndpoint) else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "sheet", value: "MovieBookingData"),
            URLQueryItem(name: "訂票日期", value: date)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
//        print("🌐 API 請求網址：\(apiEndpoint)")
//        print("📅 請求日期：\(date)")
//        print("📍 完整 URL：\(url)")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 非 HTTP 回應")
                throw URLError(.badServerResponse)
            }
            
            print("📡 HTTP 狀態碼：\(httpResponse.statusCode)")
            
            // 印出原始 JSON 資料以供檢查
            if let jsonString = String(data: data, encoding: .utf8) {
//                print("📦 原始 JSON 資料：")
                print(jsonString)
            }
            
            // 先解碼為 DTO
            let decoder = JSONDecoder()
            let dtoRecords = try decoder.decode([BookingRecordDTO].self, from: data)
            
            // 將 DTO 轉換為 BookingRecord
            let records = dtoRecords.map { $0.toBookingRecord() }
            
            print("📊 成功載入資料：\(records.count) 筆")
            records.forEach { record in
                print("""
                      🎬 電影：\(record.movieName)
                      📅 日期：\(record.showDate)
                      🕒 時間：\(record.showTime)
                      🎫 票數：\(record.numberOfTickets)
                      💺 座位：\(record.seats)
                      💰 金額：\(record.totalAmount)
                      ----------------------
                      """)
            }
            
            return records
            
        } catch {
            print("❌ 載入失敗：\(error)")
            throw error
        }
    }
    
    func fetchMovieBookings() async throws -> [BookingRecord] {
        let currentDate = Date()
        let dateString = DateFormatters.dateFormatter.string(from: currentDate)
        return try await fetchBookingRecords(for: dateString)
    }
}


