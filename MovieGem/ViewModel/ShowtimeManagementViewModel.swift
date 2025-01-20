import Foundation
import Combine

class ShowtimeManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showtimes: [MovieShowtime] = []
    @Published var theaters: [Theater] = []
    @Published var filteredShowtimes: [MovieShowtime] = []
    @Published var selectedDate: Date = Date()
    @Published var selectedStatus: MovieShowtime.ShowtimeStatus? = nil
    @Published var isLoading = false
    @Published var error: Error?
    
    private let googleSheetsService: GoogleSheetsService
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Initialization
    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)) {
        self.googleSheetsService = googleSheetsService
        loadData() // 先載入基本數據
        
        // 載入當天資料
        let today = Date()
        self.selectedDate = today
        loadBookingRecords(for: today)
        
        setupBindings() // 然後設置綁定
    }
    
    
    private func setupBindings() {
         // 降低更新頻率，避免過多請求
         $selectedDate
             .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
             .sink { [weak self] date in
                 self?.loadBookingRecords(for: date)
             }
             .store(in: &cancellables)
             
         $selectedStatus
             .sink { [weak self] status in
                 guard let self = self else { return }
                 self.filterShowtimes(date: self.selectedDate, status: status)
             }
             .store(in: &cancellables)
     }

    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: URLError(.cancelled))
                return
            }
            
            self.googleSheetsService.fetchBookingRecords(for: dateString) { result in
                switch result {
                case .success(let records):
                    continuation.resume(returning: records)
                case .failure(let error):
                    print("❌ 載入記錄失敗: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
//    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
//        return try await withCheckedThrowingContinuation { [weak self] continuation in
//            guard let self = self else {
//                continuation.resume(throwing: URLError(.cancelled))
//                return
//            }
//            
//            self.googleSheetsService.fetchBookingRecords(for: dateString) { result in
//                switch result {
//                case .success(let records):
//                    continuation.resume(returning: records)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
    
//    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
//        return try await withCheckedThrowingContinuation { [weak self] continuation in
//            self?.googleSheetsService.fetchBookingRecords(for: dateString) { result in
//                switch result {
//                case .success(let records):
//                    continuation.resume(returning: records)
//                case .failure(let error):
//                    // 處理錯誤，避免continuation洩漏
//                    print("❌ 載入記錄失敗: \(error)")
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
    
//    private func convertToShowtime(_ record: BookingRecord) -> MovieShowtime {
//        // 使用更健壮的狀態轉換
//        let status: MovieShowtime.ShowtimeStatus
//        switch record.status.lowercased() {
//        case "on sale", "onsale", "售票中":
//            status = .onSale
//        case "almost full", "almostfull", "即將額滿":
//            status = .almostFull
//        case "sold out", "soldout", "已售完":
//            status = .soldOut
//        case "canceled", "已取消":
//            status = .canceled
//        default:
//            status = .onSale  // 預設為售票中
//        }
//        
//        return MovieShowtime(
//            id: UUID().uuidString,
//            movieId: record.movieId,
//            theaterId: record.theaterId,
//            startTime: record.startTime,
//            endTime: record.endTime,
//            price: ShowtimePrice(
//                basePrice: record.price,
//                weekendPrice: nil,
//                holidayPrice: nil,
//                studentPrice: nil,
//                seniorPrice: nil,
//                childPrice: nil,
//                vipPrice: nil,
//                discounts: []
//            ),
//            status: status,
//            availableSeats: record.availableSeats
//        )
//    }
    
    private func convertToShowtime(_ record: BookingRecord) -> MovieShowtime {
        // 票價轉換
        let price = (Double(record.totalAmount) ?? 0) / (Double(record.numberOfTickets) ?? 1)
        
        // 組合日期和時間
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let startDateTime = dateFormatter.date(from: "\(record.showDate) \(record.showTime)") ?? Date()
        
        // 假設每場電影時長為 2 小時
        let endDateTime = Calendar.current.date(byAdding: .hour, value: 2, to: startDateTime) ?? startDateTime
        
        // 根據票種判斷狀態
        let status: MovieShowtime.ShowtimeStatus = .onSale  // 預設為售票中
        
        return MovieShowtime(
            id: UUID().uuidString,
            movieId: record.movieName,  // 使用電影名稱作為 movieId
            theaterId: "default",       // 可以根據需求設定預設影廳
            startTime: startDateTime,
            endTime: endDateTime,
            price: ShowtimePrice(
                basePrice: price,
                weekendPrice: nil,
                holidayPrice: nil,
                studentPrice: nil,
                seniorPrice: nil,
                childPrice: nil,
                vipPrice: nil,
                discounts: []
            ),
            status: status,
            availableSeats: 0  // 因為原始數據沒有座位數量資訊，設為預設值
        )
    }
    
    func updateSelectedStatus(_ status: MovieShowtime.ShowtimeStatus?) {
        selectedStatus = status
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        
        // 在實際應用中，這裡應該是從 API 或數據庫載入數據
        theaters = [
            Theater(id: "1", name: "第一廳", capacity: 120, type: .standard,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
            Theater(id: "2", name: "IMAX廳", capacity: 180, type: .imax,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12))
        ]
        
        showtimes = [
            MovieShowtime(
                id: "1",
                movieId: "movie1",
                theaterId: "1",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(3600 * 3),
                price: ShowtimePrice(
                    basePrice: 280,
                    weekendPrice: nil,
                    holidayPrice: nil,
                    studentPrice: nil,
                    seniorPrice: nil,
                    childPrice: nil,
                    vipPrice: nil,
                    discounts: []  // 添加空的折扣陣列
                ),
                status: .onSale,
                availableSeats: 80
            ),
            MovieShowtime(
                id: "2",
                movieId: "movie2",
                theaterId: "2",
                startTime: Date().addingTimeInterval(3600 * 4),
                endTime: Date().addingTimeInterval(3600 * 6),
                price: ShowtimePrice(
                    basePrice: 380,
                    weekendPrice: nil,
                    holidayPrice: nil,
                    studentPrice: nil,
                    seniorPrice: nil,
                    childPrice: nil,
                    vipPrice: nil,
                    discounts: []  // 添加空的折扣陣列
                ),
                status: .almostFull,
                availableSeats: 20
            )
        ]
        
        
        filterShowtimes(date: selectedDate, status: selectedStatus)
        isLoading = false
    }
    
    
    // MARK: - Showtime Management
    func updateShowtimeStatus(showtimeId: String, newStatus: MovieShowtime.ShowtimeStatus) {
        if let index = showtimes.firstIndex(where: { $0.id == showtimeId }) {
            showtimes[index].status = newStatus
            filterShowtimes(date: selectedDate, status: selectedStatus)
        }
    }
    
    func getTheaterName(for theaterId: String) -> String {
        return theaters.first(where: { $0.id == theaterId })?.name ?? "未知"
    }
    
    // MARK: - Helper Methods
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDateForQuery(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    func loadBookingRecords(for date: Date) {
        guard !isLoading else { return }
        
        isLoading = true
        let dateString = formatDateForQuery(date)
        
        Task { @MainActor in
            defer { isLoading = false }
            
            do {
                let records = try await loadRecords(for: dateString)
                
                if records.isEmpty {
                    print("⚠️ 沒有找到該日期的記錄")
                    self.showtimes = []
                    self.filteredShowtimes = []
                } else {
                    self.showtimes = records.map(convertToShowtime)
                    self.filterShowtimes(date: date, status: self.selectedStatus)
                }
                
                print("🔍 載入記錄數量: \(self.showtimes.count)")
                print("🔍 過濾後場次數: \(self.filteredShowtimes.count)")
            } catch {
                print("❌ 載入失敗: \(error)")
                self.showtimes = []
                self.filteredShowtimes = []
                
                if !(error is URLError) {
                    self.error = error
                }
            }
        }
    }
    
//    private func formatDateForQuery(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy/MM/dd"  // 使用 yyyy/MM/dd 格式
//        let formattedDate = formatter.string(from: date)
//        return formattedDate
//    }
//    
//    func loadBookingRecords(for date: Date) {
//        guard !isLoading else { return }
//        
//        isLoading = true
//        let dateString = formatDateForQuery(date)
//        
//        Task { @MainActor in
//            defer { isLoading = false }
//            
//            do {
//                let records = try await loadRecords(for: dateString)
//                
//                if records.isEmpty {
//                    self.showtimes = []
//                    self.filteredShowtimes = []
//                } else {
//                    self.showtimes = records.map(convertToShowtime)
//                    self.filterShowtimes(date: date, status: self.selectedStatus)
//                }
//                
//                print("🔍 載入記錄數量: \(self.showtimes.count)")
//                print("🔍 過濾後場次數: \(self.filteredShowtimes.count)")
//            } catch {
//                print("❌ 載入失敗: \(error)")
//                self.showtimes = []
//                self.filteredShowtimes = []
//                
//                if !(error is URLError) {
//                    self.error = error
//                }
//            }
//        }
//    }
    
    func filterShowtimes(date: Date, status: MovieShowtime.ShowtimeStatus?) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        filteredShowtimes = showtimes.filter { showtime in
            let isWithinDay = showtime.startTime >= startOfDay && showtime.startTime < endOfDay
            let statusMatch = status == nil || showtime.status == status
            return isWithinDay && statusMatch
        }
        
        print("🔍 過濾日期: \(formatDate(startOfDay))")
        print("🏷 過濾狀態: \(String(describing: status))")
        print("✅ 過濾完成，結果數量: \(filteredShowtimes.count)")
    }
    
    
//    func filterShowtimes(date: Date, status: MovieShowtime.ShowtimeStatus?) {
//        let calendar = Calendar.current
//        let startOfDay = calendar.startOfDay(for: date)
//        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
//        
//        filteredShowtimes = showtimes.filter { showtime in
//            let isWithinDay = showtime.startTime >= startOfDay && showtime.startTime < endOfDay
//            let statusMatch = status == nil || showtime.status == status
//            return isWithinDay && statusMatch
//        }
//        
//        print("🔍 過濾日期: \(formatDate(startOfDay))")
//        print("🏷 過濾狀態: \(String(describing: status))")
//        print("✅ 過濾完成，結果數量: \(filteredShowtimes.count)")
//    }

//    // 確保過濾方法更加精確
//    func filterShowtimes(date: Date, status: MovieShowtime.ShowtimeStatus?) {
//        let calendar = Calendar.current
//        filteredShowtimes = showtimes.filter { showtime in
//            let isSameDay = calendar.isDate(showtime.startTime, inSameDayAs: date)
//            let statusMatch = status == nil || showtime.status == status
//            return isSameDay && statusMatch
//        }
//        
//        print("🔍 過濾日期: \(formatDate(date))")
//        print("🏷 過濾狀態: \(String(describing: status))")
//        print("✅ 過濾完成，結果數量: \(filteredShowtimes.count)")
//    }
    
}
