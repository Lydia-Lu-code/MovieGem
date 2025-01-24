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
    @Published var datesWithData: Set<DateComponents> = []
    
    private let googleSheetsService: GoogleSheetsService
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Initialization
    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)) {
        self.googleSheetsService = googleSheetsService
        setupBindings() // 先設置綁定
        
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
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
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
    
    
    func hasData(for dateComponents: DateComponents) -> Bool {
        return datesWithData.contains { components in
            // 直接比對完整的日期組件
            return components.year == dateComponents.year &&
                   components.month == dateComponents.month &&
                   components.day == dateComponents.day
        }
    }
    
    
    func filterShowtimes(date: Date, status: MovieShowtime.ShowtimeStatus?) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        filteredShowtimes = showtimes.filter { showtime in
            let isWithinDay = showtime.startTime >= startOfDay && showtime.startTime < endOfDay
            let statusMatch = status == nil || showtime.status == status
            return isWithinDay && statusMatch
        }
    }
    
    func getShowtimeDetailsMessage(_ showtime: MovieShowtime) -> String {
        return """
        開始時間: \(formatDate(showtime.startTime))
        結束時間: \(formatDate(showtime.endTime))
        影廳: \(getTheaterName(for: showtime.theaterId))
        票價: \(showtime.price.basePrice)
        剩餘座位: \(showtime.availableSeats)
        狀態: \(showtime.status.rawValue)
        """
    }
    

        
        func isDateHasData(_ date: Date) -> Bool {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return datesWithData.contains { storedComponents in
                return storedComponents.year == components.year &&
                       storedComponents.month == components.month &&
                       storedComponents.day == components.day
            }
        }
        
        @MainActor
        private func updateDatesWithData(_ date: Date) {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            if !datesWithData.contains(where: { $0 == dateComponents }) {
                datesWithData.insert(dateComponents)
            }
        }
    
    
}


extension ShowtimeManagementViewModel {
    @MainActor
    private func updateDatesWithData(_ date: Date, withRecords records: [BookingRecord]) {
        if !records.isEmpty {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            // 確保不重複添加
            if !datesWithData.contains(dateComponents) {
                datesWithData.insert(dateComponents)
                print("✅ 更新日期數據：\(datesWithData)")
            }
        }
    }
    
    func loadBookingRecords(for date: Date) {
        guard !isLoading else { return }
        isLoading = true
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }
        
        let startDateString = formatDateForQuery(startOfMonth)
        let endDateString = formatDateForQuery(endOfMonth)
        
        Task { @MainActor in
            defer { isLoading = false }
            do {
                let records = try await loadRecords(for: startDateString)
                if !records.isEmpty {
                    // 修改 forEach 為同步操作
                    for record in records {
                        if let recordDate = parseDate(record.showDate) {
                            // 移除 await 關鍵字，確保 updateDatesWithData 是同步函數
                            updateDatesWithData(recordDate, withRecords: [record])
                        }
                    }
                }
                updateShowtimesForCurrentDate(records)
            } catch {
                print("❌ 載入失敗：\(error)")
                // 移除 handleError 調用，直接處理錯誤
                print("Error details: \(error.localizedDescription)")
            }
        }
    }
    
    
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.date(from: dateString)
    }
    
    private func updateShowtimesForCurrentDate(_ records: [BookingRecord]) {
        // 只更新當前選中日期的場次
        let currentDateString = formatDateForQuery(selectedDate)
        let currentDateRecords = records.filter { $0.showDate == currentDateString }
        
        if currentDateRecords.isEmpty {
            self.showtimes = []
            self.filteredShowtimes = []
        } else {
            self.showtimes = currentDateRecords.map(convertToShowtime)
            self.filterShowtimes(date: selectedDate, status: selectedStatus)
        }
    }
    
}

//import Foundation
//import Combine
//
//class ShowtimeManagementViewModel: ObservableObject {
//    // MARK: - Published Properties
//    @Published var showtimes: [MovieShowtime] = []
//    @Published var theaters: [Theater] = []
//    @Published var filteredShowtimes: [MovieShowtime] = []
//    @Published var selectedDate: Date = Date()
//    @Published var selectedStatus: MovieShowtime.ShowtimeStatus? = nil
//    @Published var isLoading = false
//    @Published var error: Error?
//    @Published var datesWithData: Set<DateComponents> = []
//    
//    private let googleSheetsService: GoogleSheetsService
//    private var cancellables = Set<AnyCancellable>()
//    
//    
//    // MARK: - Initialization
//    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)) {
//        self.googleSheetsService = googleSheetsService
//        setupBindings() // 先設置綁定
//        
//    }
//    
//
//    
//    
//    private func setupBindings() {
//         // 降低更新頻率，避免過多請求
//         $selectedDate
//             .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
//             .sink { [weak self] date in
//                 self?.loadBookingRecords(for: date)
//             }
//             .store(in: &cancellables)
//             
//         $selectedStatus
//             .sink { [weak self] status in
//                 guard let self = self else { return }
//                 self.filterShowtimes(date: self.selectedDate, status: status)
//             }
//             .store(in: &cancellables)
//     }
//
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
//    
//    private func convertToShowtime(_ record: BookingRecord) -> MovieShowtime {
//        // 票價轉換
//        let price = (Double(record.totalAmount) ?? 0) / (Double(record.numberOfTickets) ?? 1)
//        
//        // 組合日期和時間
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
//        let startDateTime = dateFormatter.date(from: "\(record.showDate) \(record.showTime)") ?? Date()
//        
//        // 假設每場電影時長為 2 小時
//        let endDateTime = Calendar.current.date(byAdding: .hour, value: 2, to: startDateTime) ?? startDateTime
//        
//        // 根據票種判斷狀態
//        let status: MovieShowtime.ShowtimeStatus = .onSale  // 預設為售票中
//        
//        return MovieShowtime(
//            id: UUID().uuidString,
//            movieId: record.movieName,  // 使用電影名稱作為 movieId
//            theaterId: "default",       // 可以根據需求設定預設影廳
//            startTime: startDateTime,
//            endTime: endDateTime,
//            price: ShowtimePrice(
//                basePrice: price,
//                weekendPrice: nil,
//                holidayPrice: nil,
//                studentPrice: nil,
//                seniorPrice: nil,
//                childPrice: nil,
//                vipPrice: nil,
//                discounts: []
//            ),
//            status: status,
//            availableSeats: 0  // 因為原始數據沒有座位數量資訊，設為預設值
//        )
//    }
//    
//    func updateSelectedStatus(_ status: MovieShowtime.ShowtimeStatus?) {
//        selectedStatus = status
//    }
//    
//    // MARK: - Data Loading
//    func loadData() {
//        isLoading = true
//        
//        // 在實際應用中，這裡應該是從 API 或數據庫載入數據
//        theaters = [
//            Theater(id: "1", name: "第一廳", capacity: 120, type: .standard,
//                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
//            Theater(id: "2", name: "IMAX廳", capacity: 180, type: .imax,
//                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12))
//        ]
//        
//        showtimes = [
//            MovieShowtime(
//                id: "1",
//                movieId: "movie1",
//                theaterId: "1",
//                startTime: Date().addingTimeInterval(3600),
//                endTime: Date().addingTimeInterval(3600 * 3),
//                price: ShowtimePrice(
//                    basePrice: 280,
//                    weekendPrice: nil,
//                    holidayPrice: nil,
//                    studentPrice: nil,
//                    seniorPrice: nil,
//                    childPrice: nil,
//                    vipPrice: nil,
//                    discounts: []  // 添加空的折扣陣列
//                ),
//                status: .onSale,
//                availableSeats: 80
//            ),
//            MovieShowtime(
//                id: "2",
//                movieId: "movie2",
//                theaterId: "2",
//                startTime: Date().addingTimeInterval(3600 * 4),
//                endTime: Date().addingTimeInterval(3600 * 6),
//                price: ShowtimePrice(
//                    basePrice: 380,
//                    weekendPrice: nil,
//                    holidayPrice: nil,
//                    studentPrice: nil,
//                    seniorPrice: nil,
//                    childPrice: nil,
//                    vipPrice: nil,
//                    discounts: []  // 添加空的折扣陣列
//                ),
//                status: .almostFull,
//                availableSeats: 20
//            )
//        ]
//        
//        
//        filterShowtimes(date: selectedDate, status: selectedStatus)
//        isLoading = false
//    }
//    
//    
//    // MARK: - Showtime Management
//    func updateShowtimeStatus(showtimeId: String, newStatus: MovieShowtime.ShowtimeStatus) {
//        if let index = showtimes.firstIndex(where: { $0.id == showtimeId }) {
//            showtimes[index].status = newStatus
//            filterShowtimes(date: selectedDate, status: selectedStatus)
//        }
//    }
//    
//    func getTheaterName(for theaterId: String) -> String {
//        return theaters.first(where: { $0.id == theaterId })?.name ?? "未知"
//    }
//    
//    // MARK: - Helper Methods
//    func formatDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy/MM/dd HH:mm"
//        return formatter.string(from: date)
//    }
//    
//    private func formatDateForQuery(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy/MM/dd"
//        return formatter.string(from: date)
//    }
//    
//    
//    func hasData(for dateComponents: DateComponents) -> Bool {
//        return datesWithData.contains { components in
//            // 直接比對完整的日期組件
//            return components.year == dateComponents.year &&
//                   components.month == dateComponents.month &&
//                   components.day == dateComponents.day
//        }
//    }
//    
//    
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
//    }
//    
//    func getShowtimeDetailsMessage(_ showtime: MovieShowtime) -> String {
//        return """
//        開始時間: \(formatDate(showtime.startTime))
//        結束時間: \(formatDate(showtime.endTime))
//        影廳: \(getTheaterName(for: showtime.theaterId))
//        票價: \(showtime.price.basePrice)
//        剩餘座位: \(showtime.availableSeats)
//        狀態: \(showtime.status.rawValue)
//        """
//    }
//    
//
//        
//        func isDateHasData(_ date: Date) -> Bool {
//            let calendar = Calendar.current
//            let components = calendar.dateComponents([.year, .month, .day], from: date)
//            return datesWithData.contains { storedComponents in
//                return storedComponents.year == components.year &&
//                       storedComponents.month == components.month &&
//                       storedComponents.day == components.day
//            }
//        }
//        
//        @MainActor
//        private func updateDatesWithData(_ date: Date) {
//            let calendar = Calendar.current
//            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
//            if !datesWithData.contains(where: { $0 == dateComponents }) {
//                datesWithData.insert(dateComponents)
//            }
//        }
//    
//    
//}
//
//
//extension ShowtimeManagementViewModel {
//    @MainActor
//    private func updateDatesWithData(_ date: Date, withRecords records: [BookingRecord]) {
//        if !records.isEmpty {
//            let calendar = Calendar.current
//            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
//            // 確保不重複添加
//            if !datesWithData.contains(dateComponents) {
//                datesWithData.insert(dateComponents)
//                print("✅ 更新日期數據：\(datesWithData)")
//            }
//        }
//    }
//    
//    func loadBookingRecords(for date: Date) {
//        guard !isLoading else { return }
//        isLoading = true
//        
//        let calendar = Calendar.current
//        let month = calendar.component(.month, from: date)
//        let year = calendar.component(.year, from: date)
//        
//        var components = DateComponents()
//        components.year = year
//        components.month = month
//        components.day = 1
//        
//        guard let startOfMonth = calendar.date(from: components),
//              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
//            return
//        }
//        
//        let startDateString = formatDateForQuery(startOfMonth)
//        let endDateString = formatDateForQuery(endOfMonth)
//        
//        Task { @MainActor in
//            defer { isLoading = false }
//            do {
//                let records = try await loadRecords(for: startDateString)
//                if !records.isEmpty {
//                    // 修改 forEach 為同步操作
//                    for record in records {
//                        if let recordDate = parseDate(record.showDate) {
//                            // 移除 await 關鍵字，確保 updateDatesWithData 是同步函數
//                            updateDatesWithData(recordDate, withRecords: [record])
//                        }
//                    }
//                }
//                updateShowtimesForCurrentDate(records)
//            } catch {
//                print("❌ 載入失敗：\(error)")
//                // 移除 handleError 調用，直接處理錯誤
//                print("Error details: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    
//    
//    private func parseDate(_ dateString: String) -> Date? {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy/MM/dd"
//        return formatter.date(from: dateString)
//    }
//    
//    private func updateShowtimesForCurrentDate(_ records: [BookingRecord]) {
//        // 只更新當前選中日期的場次
//        let currentDateString = formatDateForQuery(selectedDate)
//        let currentDateRecords = records.filter { $0.showDate == currentDateString }
//        
//        if currentDateRecords.isEmpty {
//            self.showtimes = []
//            self.filteredShowtimes = []
//        } else {
//            self.showtimes = currentDateRecords.map(convertToShowtime)
//            self.filterShowtimes(date: selectedDate, status: selectedStatus)
//        }
//    }
//    
//}
//
////import Foundation
////import Combine
////
////class ShowtimeManagementViewModel: ObservableObject {
////    // MARK: - Published Properties
////    @Published var showtimes: [MovieShowtime] = []
////    @Published var theaters: [Theater] = []
////    @Published var filteredShowtimes: [MovieShowtime] = []
////    @Published var selectedDate: Date = Date()
////    @Published var selectedStatus: MovieShowtime.ShowtimeStatus? = nil
////    @Published var isLoading = false
////    @Published var error: Error?
////    @Published var datesWithData: Set<DateComponents> = []
////    
////    private let googleSheetsService: GoogleSheetsService
////    private var cancellables = Set<AnyCancellable>()
////    
////    
////    // MARK: - Initialization
////    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)) {
////        self.googleSheetsService = googleSheetsService
////        setupBindings() // 先設置綁定
////        
////    }
////    
////
////    
////    
////    private func setupBindings() {
////         // 降低更新頻率，避免過多請求
////         $selectedDate
////             .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
////             .sink { [weak self] date in
////                 self?.loadBookingRecords(for: date)
////             }
////             .store(in: &cancellables)
////             
////         $selectedStatus
////             .sink { [weak self] status in
////                 guard let self = self else { return }
////                 self.filterShowtimes(date: self.selectedDate, status: status)
////             }
////             .store(in: &cancellables)
////     }
////    
////    // 在 ShowtimeManagementViewModel 中修改
////    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
////        return try await withCheckedThrowingContinuation { [weak self] continuation in
////            guard let self = self else {
////                continuation.resume(throwing: URLError(.cancelled))
////                return
////            }
////            
////            // 新增錯誤處理
////            guard !dateString.isEmpty else {
////                continuation.resume(throwing: URLError(.badURL))
////                return
////            }
////            
////            self.googleSheetsService.fetchBookingRecords(for: dateString) { result in
////                switch result {
////                case .success(let records):
////                    continuation.resume(returning: records)
////                case .failure(let error):
////                    if let urlError = error as? URLError {
////                        continuation.resume(throwing: urlError)
////                    } else {
////                        continuation.resume(throwing: URLError(.unknown))
////                    }
////                }
////            }
////        }
////    }
////
//////    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
//////        return try await withCheckedThrowingContinuation { [weak self] continuation in
//////            guard let self = self else {
//////                continuation.resume(throwing: URLError(.cancelled))
//////                return
//////            }
//////            
//////            self.googleSheetsService.fetchBookingRecords(for: dateString) { result in
//////                switch result {
//////                case .success(let records):
//////                    continuation.resume(returning: records)
//////                case .failure(let error):
//////                    continuation.resume(throwing: error)
//////                }
//////            }
//////        }
//////    }
////    
////    private func convertToShowtime(_ record: BookingRecord) -> MovieShowtime {
////        // 票價轉換
////        let price = (Double(record.totalAmount) ?? 0) / (Double(record.numberOfTickets) ?? 1)
////        
////        // 組合日期和時間
////        let dateFormatter = DateFormatter()
////        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
////        let startDateTime = dateFormatter.date(from: "\(record.showDate) \(record.showTime)") ?? Date()
////        
////        // 假設每場電影時長為 2 小時
////        let endDateTime = Calendar.current.date(byAdding: .hour, value: 2, to: startDateTime) ?? startDateTime
////        
////        // 根據票種判斷狀態
////        let status: MovieShowtime.ShowtimeStatus = .onSale  // 預設為售票中
////        
////        return MovieShowtime(
////            id: UUID().uuidString,
////            movieId: record.movieName,  // 使用電影名稱作為 movieId
////            theaterId: "default",       // 可以根據需求設定預設影廳
////            startTime: startDateTime,
////            endTime: endDateTime,
////            price: ShowtimePrice(
////                basePrice: price,
////                weekendPrice: nil,
////                holidayPrice: nil,
////                studentPrice: nil,
////                seniorPrice: nil,
////                childPrice: nil,
////                vipPrice: nil,
////                discounts: []
////            ),
////            status: status,
////            availableSeats: 0  // 因為原始數據沒有座位數量資訊，設為預設值
////        )
////    }
////    
////    func updateSelectedStatus(_ status: MovieShowtime.ShowtimeStatus?) {
////        selectedStatus = status
////    }
////    
////    // MARK: - Data Loading
////    func loadData() {
////        isLoading = true
////        
////        // 在實際應用中，這裡應該是從 API 或數據庫載入數據
////        theaters = [
////            Theater(id: "1", name: "第一廳", capacity: 120, type: .standard,
////                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
////            Theater(id: "2", name: "IMAX廳", capacity: 180, type: .imax,
////                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12))
////        ]
////        
////        showtimes = [
////            MovieShowtime(
////                id: "1",
////                movieId: "movie1",
////                theaterId: "1",
////                startTime: Date().addingTimeInterval(3600),
////                endTime: Date().addingTimeInterval(3600 * 3),
////                price: ShowtimePrice(
////                    basePrice: 280,
////                    weekendPrice: nil,
////                    holidayPrice: nil,
////                    studentPrice: nil,
////                    seniorPrice: nil,
////                    childPrice: nil,
////                    vipPrice: nil,
////                    discounts: []  // 添加空的折扣陣列
////                ),
////                status: .onSale,
////                availableSeats: 80
////            ),
////            MovieShowtime(
////                id: "2",
////                movieId: "movie2",
////                theaterId: "2",
////                startTime: Date().addingTimeInterval(3600 * 4),
////                endTime: Date().addingTimeInterval(3600 * 6),
////                price: ShowtimePrice(
////                    basePrice: 380,
////                    weekendPrice: nil,
////                    holidayPrice: nil,
////                    studentPrice: nil,
////                    seniorPrice: nil,
////                    childPrice: nil,
////                    vipPrice: nil,
////                    discounts: []  // 添加空的折扣陣列
////                ),
////                status: .almostFull,
////                availableSeats: 20
////            )
////        ]
////        
////        
////        filterShowtimes(date: selectedDate, status: selectedStatus)
////        isLoading = false
////    }
////    
////    
////    // MARK: - Showtime Management
////    func updateShowtimeStatus(showtimeId: String, newStatus: MovieShowtime.ShowtimeStatus) {
////        if let index = showtimes.firstIndex(where: { $0.id == showtimeId }) {
////            showtimes[index].status = newStatus
////            filterShowtimes(date: selectedDate, status: selectedStatus)
////        }
////    }
////    
////    func getTheaterName(for theaterId: String) -> String {
////        return theaters.first(where: { $0.id == theaterId })?.name ?? "未知"
////    }
////    
////    // MARK: - Helper Methods
////    func formatDate(_ date: Date) -> String {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "yyyy/MM/dd HH:mm"
////        return formatter.string(from: date)
////    }
////    
////    private func formatDateForQuery(_ date: Date) -> String {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "yyyy/MM/dd"
////        return formatter.string(from: date)
////    }
////    
////    
////    func hasData(for dateComponents: DateComponents) -> Bool {
////        return datesWithData.contains { components in
////            // 直接比對完整的日期組件
////            return components.year == dateComponents.year &&
////                   components.month == dateComponents.month &&
////                   components.day == dateComponents.day
////        }
////    }
////    
////    
////    func filterShowtimes(date: Date, status: MovieShowtime.ShowtimeStatus?) {
////        let calendar = Calendar.current
////        let startOfDay = calendar.startOfDay(for: date)
////        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
////        
////        filteredShowtimes = showtimes.filter { showtime in
////            let isWithinDay = showtime.startTime >= startOfDay && showtime.startTime < endOfDay
////            let statusMatch = status == nil || showtime.status == status
////            return isWithinDay && statusMatch
////        }
////    }
////    
////    func getShowtimeDetailsMessage(_ showtime: MovieShowtime) -> String {
////        return """
////        開始時間: \(formatDate(showtime.startTime))
////        結束時間: \(formatDate(showtime.endTime))
////        影廳: \(getTheaterName(for: showtime.theaterId))
////        票價: \(showtime.price.basePrice)
////        剩餘座位: \(showtime.availableSeats)
////        狀態: \(showtime.status.rawValue)
////        """
////    }
////    
////    func isDateHasData(_ date: Date) -> Bool {
////        let calendar = Calendar.current
////        let components = calendar.dateComponents([.year, .month, .day], from: date)
////        
////        return datesWithData.contains { storedComponents in
////            return storedComponents.year == components.year &&
////                   storedComponents.month == components.month &&
////                   storedComponents.day == components.day
////        }
////    }
////        
//////        func isDateHasData(_ date: Date) -> Bool {
//////            let calendar = Calendar.current
//////            let components = calendar.dateComponents([.year, .month, .day], from: date)
//////            return datesWithData.contains { storedComponents in
//////                return storedComponents.year == components.year &&
//////                       storedComponents.month == components.month &&
//////                       storedComponents.day == components.day
//////            }
//////        }
////        
////        @MainActor
////        private func updateDatesWithData(_ date: Date) {
////            let calendar = Calendar.current
////            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
////            if !datesWithData.contains(where: { $0 == dateComponents }) {
////                datesWithData.insert(dateComponents)
////            }
////        }
////    
////    
////}
////
////
////extension ShowtimeManagementViewModel {
////    @MainActor
////    private func updateDatesWithData(_ date: Date, withRecords records: [BookingRecord]) {
////        if !records.isEmpty {
////            let calendar = Calendar.current
////            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
////            // 確保不重複添加
////            if !datesWithData.contains(dateComponents) {
////                datesWithData.insert(dateComponents)
////            }
////        }
////    }
////    
////    func loadBookingRecords(for date: Date) {
////        guard !isLoading else { return }
////        isLoading = true
////        
////        let dateString = formatDateForQuery(date)
////        print("正在載入日期：\(dateString)") // 添加這行來檢查日期
////
////        Task { @MainActor in
////            defer { isLoading = false }
////            do {
////                let records = try await loadRecords(for: dateString)
////                if !records.isEmpty {
////                    print("成功載入記錄：\(records.count) 條") // 添加這行來檢查記錄數量
////                    for record in records {
////                        if let recordDate = parseDate(record.showDate) {
////                            updateDatesWithData(recordDate, withRecords: [record])
////                        }
////                    }
////                    updateShowtimesForCurrentDate(records)
////                } else {
////                    print("沒有找到記錄")
////                    self.showtimes = []
////                    self.filteredShowtimes = []
////                }
////            } catch {
////                print("載入失敗：\(error)")
////                // 添加更詳細的錯誤處理
////                self.error = error
////                self.showtimes = []
////                self.filteredShowtimes = []
////            }
////        }
////    }
////
//////    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
//////        return try await withCheckedThrowingContinuation { [weak self] continuation in
//////            guard let self = self else {
//////                continuation.resume(throwing: URLError(.cancelled))
//////                return
//////            }
//////            
//////            self.googleSheetsService.fetchBookingRecords(for: dateString) { result in
//////                switch result {
//////                case .success(let records):
//////                    continuation.resume(returning: records)
//////                case .failure(let error):
//////                    // 添加更多錯誤資訊
//////                    print("API錯誤：\(error)")
//////                    if let urlError = error as? URLError {
//////                        continuation.resume(throwing: urlError)
//////                    } else {
//////                        continuation.resume(throwing: URLError(.unknown))
//////                    }
//////                }
//////            }
//////        }
//////    }
////    
//////    func loadBookingRecords(for date: Date) {
//////        guard !isLoading else { return }
//////        isLoading = true
//////        
//////        let calendar = Calendar.current
//////        let month = calendar.component(.month, from: date)
//////        let year = calendar.component(.year, from: date)
//////        
//////        var components = DateComponents()
//////        components.year = year
//////        components.month = month
//////        components.day = 1
//////        
//////        guard let startOfMonth = calendar.date(from: components),
//////              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
//////            return
//////        }
//////        
//////        let startDateString = formatDateForQuery(startOfMonth)
//////        let endDateString = formatDateForQuery(endOfMonth)
//////        
//////        Task { @MainActor in
//////            defer { isLoading = false }
//////            do {
//////                let records = try await loadRecords(for: startDateString)
//////                if !records.isEmpty {
//////                    // 修改 forEach 為同步操作
//////                    for record in records {
//////                        if let recordDate = parseDate(record.showDate) {
//////                            // 移除 await 關鍵字，確保 updateDatesWithData 是同步函數
//////                            updateDatesWithData(recordDate, withRecords: [record])
//////                        }
//////                    }
//////                }
//////                updateShowtimesForCurrentDate(records)
//////            } catch {
//////                print("❌ 載入失敗：\(error)")
//////                // 移除 handleError 調用，直接處理錯誤
//////                print("Error details: \(error.localizedDescription)")
//////            }
//////        }
//////    }
////    
////    
////    
////    private func parseDate(_ dateString: String) -> Date? {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "yyyy/MM/dd"
////        return formatter.date(from: dateString)
////    }
////    
////    private func updateShowtimesForCurrentDate(_ records: [BookingRecord]) {
////        // 只更新當前選中日期的場次
////        let currentDateString = formatDateForQuery(selectedDate)
////        let currentDateRecords = records.filter { $0.showDate == currentDateString }
////        
////        if currentDateRecords.isEmpty {
////            self.showtimes = []
////            self.filteredShowtimes = []
////        } else {
////            self.showtimes = currentDateRecords.map(convertToShowtime)
////            self.filterShowtimes(date: selectedDate, status: selectedStatus)
////        }
////    }
////    
////}
////
//////import Foundation
//////import Combine
//////
//////class ShowtimeManagementViewModel: ObservableObject {
//////    // MARK: - Published Properties
//////    @Published var showtimes: [MovieShowtime] = []
//////    @Published var theaters: [Theater] = []
//////    @Published var filteredShowtimes: [MovieShowtime] = []
//////    @Published var selectedDate: Date = Date()
//////    @Published var selectedStatus: MovieShowtime.ShowtimeStatus? = nil
//////    @Published var isLoading = false
//////    @Published var error: Error?
//////    @Published var datesWithData: Set<DateComponents> = []
//////    
//////    private let googleSheetsService: GoogleSheetsService
//////    private var cancellables = Set<AnyCancellable>()
//////    
//////    
//////    // MARK: - Initialization
//////    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)) {
//////        self.googleSheetsService = googleSheetsService
//////        setupBindings() // 先設置綁定
//////        
//////    }
//////    
//////
//////    
//////    
//////    private func setupBindings() {
//////         // 降低更新頻率，避免過多請求
//////         $selectedDate
//////             .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
//////             .sink { [weak self] date in
//////                 self?.loadBookingRecords(for: date)
//////             }
//////             .store(in: &cancellables)
//////             
//////         $selectedStatus
//////             .sink { [weak self] status in
//////                 guard let self = self else { return }
//////                 self.filterShowtimes(date: self.selectedDate, status: status)
//////             }
//////             .store(in: &cancellables)
//////     }
//////
//////    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
//////        return try await withCheckedThrowingContinuation { [weak self] continuation in
//////            guard let self = self else {
//////                continuation.resume(throwing: URLError(.cancelled))
//////                return
//////            }
//////            
//////            self.googleSheetsService.fetchBookingRecords(for: dateString) { result in
//////                switch result {
//////                case .success(let records):
//////                    continuation.resume(returning: records)
//////                case .failure(let error):
//////                    continuation.resume(throwing: error)
//////                }
//////            }
//////        }
//////    }
//////    
//////    private func convertToShowtime(_ record: BookingRecord) -> MovieShowtime {
//////        // 票價轉換
//////        let price = (Double(record.totalAmount) ?? 0) / (Double(record.numberOfTickets) ?? 1)
//////        
//////        // 組合日期和時間
//////        let dateFormatter = DateFormatter()
//////        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
//////        let startDateTime = dateFormatter.date(from: "\(record.showDate) \(record.showTime)") ?? Date()
//////        
//////        // 假設每場電影時長為 2 小時
//////        let endDateTime = Calendar.current.date(byAdding: .hour, value: 2, to: startDateTime) ?? startDateTime
//////        
//////        // 根據票種判斷狀態
//////        let status: MovieShowtime.ShowtimeStatus = .onSale  // 預設為售票中
//////        
//////        return MovieShowtime(
//////            id: UUID().uuidString,
//////            movieId: record.movieName,  // 使用電影名稱作為 movieId
//////            theaterId: "default",       // 可以根據需求設定預設影廳
//////            startTime: startDateTime,
//////            endTime: endDateTime,
//////            price: ShowtimePrice(
//////                basePrice: price,
//////                weekendPrice: nil,
//////                holidayPrice: nil,
//////                studentPrice: nil,
//////                seniorPrice: nil,
//////                childPrice: nil,
//////                vipPrice: nil,
//////                discounts: []
//////            ),
//////            status: status,
//////            availableSeats: 0  // 因為原始數據沒有座位數量資訊，設為預設值
//////        )
//////    }
//////    
//////    func updateSelectedStatus(_ status: MovieShowtime.ShowtimeStatus?) {
//////        selectedStatus = status
//////    }
//////    
//////    // MARK: - Data Loading
//////    func loadData() {
//////        isLoading = true
//////        
//////        // 在實際應用中，這裡應該是從 API 或數據庫載入數據
//////        theaters = [
//////            Theater(id: "1", name: "第一廳", capacity: 120, type: .standard,
//////                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
//////            Theater(id: "2", name: "IMAX廳", capacity: 180, type: .imax,
//////                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12))
//////        ]
//////        
//////        showtimes = [
//////            MovieShowtime(
//////                id: "1",
//////                movieId: "movie1",
//////                theaterId: "1",
//////                startTime: Date().addingTimeInterval(3600),
//////                endTime: Date().addingTimeInterval(3600 * 3),
//////                price: ShowtimePrice(
//////                    basePrice: 280,
//////                    weekendPrice: nil,
//////                    holidayPrice: nil,
//////                    studentPrice: nil,
//////                    seniorPrice: nil,
//////                    childPrice: nil,
//////                    vipPrice: nil,
//////                    discounts: []  // 添加空的折扣陣列
//////                ),
//////                status: .onSale,
//////                availableSeats: 80
//////            ),
//////            MovieShowtime(
//////                id: "2",
//////                movieId: "movie2",
//////                theaterId: "2",
//////                startTime: Date().addingTimeInterval(3600 * 4),
//////                endTime: Date().addingTimeInterval(3600 * 6),
//////                price: ShowtimePrice(
//////                    basePrice: 380,
//////                    weekendPrice: nil,
//////                    holidayPrice: nil,
//////                    studentPrice: nil,
//////                    seniorPrice: nil,
//////                    childPrice: nil,
//////                    vipPrice: nil,
//////                    discounts: []  // 添加空的折扣陣列
//////                ),
//////                status: .almostFull,
//////                availableSeats: 20
//////            )
//////        ]
//////        
//////        
//////        filterShowtimes(date: selectedDate, status: selectedStatus)
//////        isLoading = false
//////    }
//////    
//////    
//////    // MARK: - Showtime Management
//////    func updateShowtimeStatus(showtimeId: String, newStatus: MovieShowtime.ShowtimeStatus) {
//////        if let index = showtimes.firstIndex(where: { $0.id == showtimeId }) {
//////            showtimes[index].status = newStatus
//////            filterShowtimes(date: selectedDate, status: selectedStatus)
//////        }
//////    }
//////    
//////    func getTheaterName(for theaterId: String) -> String {
//////        return theaters.first(where: { $0.id == theaterId })?.name ?? "未知"
//////    }
//////    
//////    // MARK: - Helper Methods
//////    func formatDate(_ date: Date) -> String {
//////        let formatter = DateFormatter()
//////        formatter.dateFormat = "yyyy/MM/dd HH:mm"
//////        return formatter.string(from: date)
//////    }
//////    
//////    private func formatDateForQuery(_ date: Date) -> String {
//////        let formatter = DateFormatter()
//////        formatter.dateFormat = "yyyy/MM/dd"
//////        return formatter.string(from: date)
//////    }
//////    
//////    
//////    func hasData(for dateComponents: DateComponents) -> Bool {
//////        return datesWithData.contains { components in
//////            // 直接比對完整的日期組件
//////            return components.year == dateComponents.year &&
//////                   components.month == dateComponents.month &&
//////                   components.day == dateComponents.day
//////        }
//////    }
//////    
//////    
//////    func filterShowtimes(date: Date, status: MovieShowtime.ShowtimeStatus?) {
//////        let calendar = Calendar.current
//////        let startOfDay = calendar.startOfDay(for: date)
//////        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
//////        
//////        filteredShowtimes = showtimes.filter { showtime in
//////            let isWithinDay = showtime.startTime >= startOfDay && showtime.startTime < endOfDay
//////            let statusMatch = status == nil || showtime.status == status
//////            return isWithinDay && statusMatch
//////        }
//////    }
//////    
//////    func getShowtimeDetailsMessage(_ showtime: MovieShowtime) -> String {
//////        return """
//////        開始時間: \(formatDate(showtime.startTime))
//////        結束時間: \(formatDate(showtime.endTime))
//////        影廳: \(getTheaterName(for: showtime.theaterId))
//////        票價: \(showtime.price.basePrice)
//////        剩餘座位: \(showtime.availableSeats)
//////        狀態: \(showtime.status.rawValue)
//////        """
//////    }
//////    
//////
//////        
//////        func isDateHasData(_ date: Date) -> Bool {
//////            let calendar = Calendar.current
//////            let components = calendar.dateComponents([.year, .month, .day], from: date)
//////            return datesWithData.contains { storedComponents in
//////                return storedComponents.year == components.year &&
//////                       storedComponents.month == components.month &&
//////                       storedComponents.day == components.day
//////            }
//////        }
//////        
//////        @MainActor
//////        private func updateDatesWithData(_ date: Date) {
//////            let calendar = Calendar.current
//////            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
//////            if !datesWithData.contains(where: { $0 == dateComponents }) {
//////                datesWithData.insert(dateComponents)
//////            }
//////        }
//////    
//////    
//////}
//////
//////
//////extension ShowtimeManagementViewModel {
//////    @MainActor
//////    private func updateDatesWithData(_ date: Date, withRecords records: [BookingRecord]) {
//////        if !records.isEmpty {
//////            let calendar = Calendar.current
//////            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
//////            // 確保不重複添加
//////            if !datesWithData.contains(dateComponents) {
//////                datesWithData.insert(dateComponents)
//////                print("✅ 更新日期數據：\(datesWithData)")
//////            }
//////        }
//////    }
//////    
//////    func loadBookingRecords(for date: Date) {
//////        guard !isLoading else { return }
//////        isLoading = true
//////        
//////        let calendar = Calendar.current
//////        let month = calendar.component(.month, from: date)
//////        let year = calendar.component(.year, from: date)
//////        
//////        var components = DateComponents()
//////        components.year = year
//////        components.month = month
//////        components.day = 1
//////        
//////        guard let startOfMonth = calendar.date(from: components),
//////              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
//////            return
//////        }
//////        
//////        let startDateString = formatDateForQuery(startOfMonth)
//////        let endDateString = formatDateForQuery(endOfMonth)
//////        
//////        Task { @MainActor in
//////            defer { isLoading = false }
//////            do {
//////                let records = try await loadRecords(for: startDateString)
//////                if !records.isEmpty {
//////                    // 修改 forEach 為同步操作
//////                    for record in records {
//////                        if let recordDate = parseDate(record.showDate) {
//////                            // 移除 await 關鍵字，確保 updateDatesWithData 是同步函數
//////                            updateDatesWithData(recordDate, withRecords: [record])
//////                        }
//////                    }
//////                }
//////                updateShowtimesForCurrentDate(records)
//////            } catch {
//////                print("❌ 載入失敗：\(error)")
//////                // 移除 handleError 調用，直接處理錯誤
//////                print("Error details: \(error.localizedDescription)")
//////            }
//////        }
//////    }
//////    
//////    
//////    
//////    private func parseDate(_ dateString: String) -> Date? {
//////        let formatter = DateFormatter()
//////        formatter.dateFormat = "yyyy/MM/dd"
//////        return formatter.date(from: dateString)
//////    }
//////    
//////    private func updateShowtimesForCurrentDate(_ records: [BookingRecord]) {
//////        // 只更新當前選中日期的場次
//////        let currentDateString = formatDateForQuery(selectedDate)
//////        let currentDateRecords = records.filter { $0.showDate == currentDateString }
//////        
//////        if currentDateRecords.isEmpty {
//////            self.showtimes = []
//////            self.filteredShowtimes = []
//////        } else {
//////            self.showtimes = currentDateRecords.map(convertToShowtime)
//////            self.filterShowtimes(date: selectedDate, status: selectedStatus)
//////        }
//////    }
//////    
//////}
////
//////import Foundation
//////import Combine
//////
//////class ShowtimeManagementViewModel: ObservableObject {
//////    // MARK: - Published Properties
//////    @Published var showtimes: [MovieShowtime] = []
//////    @Published var theaters: [Theater] = []
//////    @Published var filteredShowtimes: [MovieShowtime] = []
//////    @Published var selectedDate: Date = Date()
//////    @Published var selectedStatus: MovieShowtime.ShowtimeStatus? = nil
//////    @Published var isLoading = false
//////    @Published var error: Error?
//////    @Published var datesWithData: Set<DateComponents> = []
//////    
//////    private let googleSheetsService: GoogleSheetsService
//////    private var cancellables = Set<AnyCancellable>()
//////    
//////    
//////    // MARK: - Initialization
//////    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)) {
//////        self.googleSheetsService = googleSheetsService
//////        setupBindings() // 先設置綁定
//////        
//////    }
//////    
//////
//////    
//////    
//////    private func setupBindings() {
//////         // 降低更新頻率，避免過多請求
//////         $selectedDate
//////             .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
//////             .sink { [weak self] date in
//////                 self?.loadBookingRecords(for: date)
//////             }
//////             .store(in: &cancellables)
//////             
//////         $selectedStatus
//////             .sink { [weak self] status in
//////                 guard let self = self else { return }
//////                 self.filterShowtimes(date: self.selectedDate, status: status)
//////             }
//////             .store(in: &cancellables)
//////        
//////        
//////     }
//////
//////    private func loadRecords(for dateString: String) async throws -> [BookingRecord] {
//////        return try await withCheckedThrowingContinuation { [weak self] continuation in
//////            guard let self = self else {
//////                continuation.resume(throwing: URLError(.cancelled))
//////                return
//////            }
//////            
//////            self.googleSheetsService.fetchBookingRecords(for: dateString) { result in
//////                switch result {
//////                case .success(let records):
//////                    continuation.resume(returning: records)
//////                case .failure(let error):
//////                    continuation.resume(throwing: error)
//////                }
//////            }
//////        }
//////    }
//////    
//////    private func convertToShowtime(_ record: BookingRecord) -> MovieShowtime {
//////        // 票價轉換
//////        let price = (Double(record.totalAmount) ?? 0) / (Double(record.numberOfTickets) ?? 1)
//////        
//////        // 組合日期和時間
//////        let dateFormatter = DateFormatter()
//////        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
//////        let startDateTime = dateFormatter.date(from: "\(record.showDate) \(record.showTime)") ?? Date()
//////        
//////        // 假設每場電影時長為 2 小時
//////        let endDateTime = Calendar.current.date(byAdding: .hour, value: 2, to: startDateTime) ?? startDateTime
//////        
//////        // 根據票種判斷狀態
//////        let status: MovieShowtime.ShowtimeStatus = .onSale  // 預設為售票中
//////        
//////        return MovieShowtime(
//////            id: UUID().uuidString,
//////            movieId: record.movieName,  // 使用電影名稱作為 movieId
//////            theaterId: "default",       // 可以根據需求設定預設影廳
//////            startTime: startDateTime,
//////            endTime: endDateTime,
//////            price: ShowtimePrice(
//////                basePrice: price,
//////                weekendPrice: nil,
//////                holidayPrice: nil,
//////                studentPrice: nil,
//////                seniorPrice: nil,
//////                childPrice: nil,
//////                vipPrice: nil,
//////                discounts: []
//////            ),
//////            status: status,
//////            availableSeats: 0  // 因為原始數據沒有座位數量資訊，設為預設值
//////        )
//////    }
//////    
//////    func updateSelectedStatus(_ status: MovieShowtime.ShowtimeStatus?) {
//////        selectedStatus = status
//////    }
//////    
//////    // MARK: - Data Loading
//////    func loadData() {
//////        isLoading = true
//////        
//////        // 在實際應用中，這裡應該是從 API 或數據庫載入數據
//////        theaters = [
//////            Theater(id: "1", name: "第一廳", capacity: 120, type: .standard,
//////                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
//////            Theater(id: "2", name: "IMAX廳", capacity: 180, type: .imax,
//////                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12))
//////        ]
//////        
//////        showtimes = [
//////            MovieShowtime(
//////                id: "1",
//////                movieId: "movie1",
//////                theaterId: "1",
//////                startTime: Date().addingTimeInterval(3600),
//////                endTime: Date().addingTimeInterval(3600 * 3),
//////                price: ShowtimePrice(
//////                    basePrice: 280,
//////                    weekendPrice: nil,
//////                    holidayPrice: nil,
//////                    studentPrice: nil,
//////                    seniorPrice: nil,
//////                    childPrice: nil,
//////                    vipPrice: nil,
//////                    discounts: []  // 添加空的折扣陣列
//////                ),
//////                status: .onSale,
//////                availableSeats: 80
//////            ),
//////            MovieShowtime(
//////                id: "2",
//////                movieId: "movie2",
//////                theaterId: "2",
//////                startTime: Date().addingTimeInterval(3600 * 4),
//////                endTime: Date().addingTimeInterval(3600 * 6),
//////                price: ShowtimePrice(
//////                    basePrice: 380,
//////                    weekendPrice: nil,
//////                    holidayPrice: nil,
//////                    studentPrice: nil,
//////                    seniorPrice: nil,
//////                    childPrice: nil,
//////                    vipPrice: nil,
//////                    discounts: []  // 添加空的折扣陣列
//////                ),
//////                status: .almostFull,
//////                availableSeats: 20
//////            )
//////        ]
//////        
//////        
//////        filterShowtimes(date: selectedDate, status: selectedStatus)
//////        isLoading = false
//////    }
//////    
//////    
//////    // MARK: - Showtime Management
//////    func updateShowtimeStatus(showtimeId: String, newStatus: MovieShowtime.ShowtimeStatus) {
//////        if let index = showtimes.firstIndex(where: { $0.id == showtimeId }) {
//////            showtimes[index].status = newStatus
//////            filterShowtimes(date: selectedDate, status: selectedStatus)
//////        }
//////    }
//////    
//////    func getTheaterName(for theaterId: String) -> String {
//////        return theaters.first(where: { $0.id == theaterId })?.name ?? "未知"
//////    }
//////    
//////    // MARK: - Helper Methods
//////    func formatDate(_ date: Date) -> String {
//////        let formatter = DateFormatter()
//////        formatter.dateFormat = "yyyy/MM/dd HH:mm"
//////        return formatter.string(from: date)
//////    }
//////    
//////    private func formatDateForQuery(_ date: Date) -> String {
//////        let formatter = DateFormatter()
//////        formatter.dateFormat = "yyyy/MM/dd"
//////        return formatter.string(from: date)
//////    }
//////    
//////    
//////    func hasData(for dateComponents: DateComponents) -> Bool {
//////        return datesWithData.contains { components in
//////            // 直接比對完整的日期組件
//////            return components.year == dateComponents.year &&
//////                   components.month == dateComponents.month &&
//////                   components.day == dateComponents.day
//////        }
//////    }
//////    
//////    
//////    func filterShowtimes(date: Date, status: MovieShowtime.ShowtimeStatus?) {
//////        let calendar = Calendar.current
//////        let startOfDay = calendar.startOfDay(for: date)
//////        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
//////        
//////        filteredShowtimes = showtimes.filter { showtime in
//////            let isWithinDay = showtime.startTime >= startOfDay && showtime.startTime < endOfDay
//////            let statusMatch = status == nil || showtime.status == status
//////            return isWithinDay && statusMatch
//////        }
//////    }
//////    
//////    func getShowtimeDetailsMessage(_ showtime: MovieShowtime) -> String {
//////        return """
//////        開始時間: \(formatDate(showtime.startTime))
//////        結束時間: \(formatDate(showtime.endTime))
//////        影廳: \(getTheaterName(for: showtime.theaterId))
//////        票價: \(showtime.price.basePrice)
//////        剩餘座位: \(showtime.availableSeats)
//////        狀態: \(showtime.status.rawValue)
//////        """
//////    }
//////    
//////
//////        
//////        func isDateHasData(_ date: Date) -> Bool {
//////            let calendar = Calendar.current
//////            let components = calendar.dateComponents([.year, .month, .day], from: date)
//////            return datesWithData.contains { storedComponents in
//////                return storedComponents.year == components.year &&
//////                       storedComponents.month == components.month &&
//////                       storedComponents.day == components.day
//////            }
//////        }
//////        
//////        @MainActor
//////        private func updateDatesWithData(_ date: Date) {
//////            let calendar = Calendar.current
//////            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
//////            if !datesWithData.contains(where: { $0 == dateComponents }) {
//////                datesWithData.insert(dateComponents)
//////            }
//////        }
//////    
//////    
//////}
//////
//////
//////extension ShowtimeManagementViewModel {
//////    @MainActor
//////    private func updateDatesWithData(_ date: Date, withRecords records: [BookingRecord]) {
//////        if !records.isEmpty {
//////            let calendar = Calendar.current
//////            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
//////            // 確保不重複添加
//////            if !datesWithData.contains(dateComponents) {
//////                datesWithData.insert(dateComponents)
//////            }
//////        }
//////    }
//////    
//////    func loadBookingRecords(for date: Date) {
//////        guard !isLoading else { return }
//////        isLoading = true
//////        
//////        let calendar = Calendar.current
//////        let month = calendar.component(.month, from: date)
//////        let year = calendar.component(.year, from: date)
//////        
//////        var components = DateComponents()
//////        components.year = year
//////        components.month = month
//////        components.day = 1
//////        
//////        guard let startOfMonth = calendar.date(from: components),
//////              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
//////            return
//////        }
//////        
//////        let startDateString = formatDateForQuery(startOfMonth)
//////        let endDateString = formatDateForQuery(endOfMonth)
//////        
//////        Task { @MainActor in
//////            defer { isLoading = false }
//////            do {
//////                let records = try await loadRecords(for: startDateString)
//////                if !records.isEmpty {
//////                    // 修改 forEach 為同步操作
//////                    for record in records {
//////                        if let recordDate = parseDate(record.showDate) {
//////                            // 移除 await 關鍵字，確保 updateDatesWithData 是同步函數
//////                            updateDatesWithData(recordDate, withRecords: [record])
//////                        }
//////                    }
//////                }
//////                updateShowtimesForCurrentDate(records)
//////            } catch {
//////                print("❌ 載入失敗：\(error)")
//////                // 移除 handleError 調用，直接處理錯誤
//////                print("Error details: \(error.localizedDescription)")
//////            }
//////        }
//////    }
//////    
//////    
//////    
//////    private func parseDate(_ dateString: String) -> Date? {
//////        let formatter = DateFormatter()
//////        formatter.dateFormat = "yyyy/MM/dd"
//////        return formatter.date(from: dateString)
//////    }
//////    
//////    private func updateShowtimesForCurrentDate(_ records: [BookingRecord]) {
//////        // 只更新當前選中日期的場次
//////        let currentDateString = formatDateForQuery(selectedDate)
//////        let currentDateRecords = records.filter { $0.showDate == currentDateString }
//////        
//////        if currentDateRecords.isEmpty {
//////            self.showtimes = []
//////            self.filteredShowtimes = []
//////        } else {
//////            self.showtimes = currentDateRecords.map(convertToShowtime)
//////            self.filterShowtimes(date: selectedDate, status: selectedStatus)
//////        }
//////    }
//////    
//////}
