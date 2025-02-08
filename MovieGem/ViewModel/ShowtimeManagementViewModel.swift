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
    
    // MARK: - Private Properties
    private let googleSheetsService: GoogleSheetsService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService()) {
        self.googleSheetsService = googleSheetsService
        setupBindings()
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        // 只保留一個事件訂閱
        $selectedDate
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()  // 添加去重
            .sink { [weak self] date in
                print("📅 選擇日期：\(date)")
                self?.loadBookingRecords(for: date)
            }
            .store(in: &cancellables)
    }
    
//    private func setupBindings() {
//        $selectedDate
//            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
//            .sink { [weak self] date in
//                self?.loadBookingRecords(for: date)
//            }
//            .store(in: &cancellables)
//        
//        $selectedStatus
//            .sink { [weak self] status in
//                guard let self = self else { return }
//                self.filterShowtimes(date: self.selectedDate, status: status)
//            }
//            .store(in: &cancellables)
//    }
    
    // MARK: - Public Methods
    @MainActor
//    func loadInitialData() {
    func loadInitialData() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // 載入當前日期的資料
            loadBookingRecords(for: selectedDate)
            
            // 載入當月的資料以顯示藍點
            let calendar = Calendar.current
            let currentMonth = calendar.dateComponents([.year, .month], from: selectedDate)
            if let startOfMonth = calendar.date(from: currentMonth),
               let range = calendar.range(of: .day, in: .month, for: startOfMonth) {
                for day in range {
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                        loadBookingRecords(for: date)
                    }
                }
            }
        }
    }
    
    func loadBookingRecords(for date: Date) {
        guard !isLoading else { return }
        isLoading = true
        
        selectedDate = date  // 更新選中日期
        let dateString = formatDateForQuery(date)
        
        Task { @MainActor in
            defer { isLoading = false }
            do {
                let records = try await loadRecords(for: dateString)
                if !records.isEmpty {
                    for record in records {
                        if let recordDate = parseDate(record.showDate) {
                            updateDatesWithData(recordDate, withRecords: [record])
                        }
                    }
                }
                updateShowtimesForCurrentDate(records)
                
            } catch {
                self.error = error
                print("載入失敗：\(error)")
            }
        }
    }
    
//    func loadBookingRecords(for date: Date) {
//        guard !isLoading else { return }
//        isLoading = true
//        
//        let dateString = formatDateForQuery(date)
//        
//        Task { @MainActor in
//            defer { isLoading = false }
//            do {
//                let records = try await loadRecords(for: dateString)
//                if !records.isEmpty {
//                    for record in records {
//                        if let recordDate = parseDate(record.showDate) {
//                            updateDatesWithData(recordDate, withRecords: [record])
//                        }
//                    }
//                }
//                updateShowtimesForCurrentDate(records)
//            } catch {
//                self.error = error
//                print("載入失敗：\(error)")
//            }
//        }
//    }
    
    func updateSelectedStatus(_ status: MovieShowtime.ShowtimeStatus?) {
        selectedStatus = status
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
        
        func getTheaterName(for theaterId: String) -> String {
            return theaters.first(where: { $0.id == theaterId })?.name ?? "未知"
        }
        
        // MARK: - Private Methods
        private func loadRecords(for date: String) async throws -> [BookingRecord] {
            return try await googleSheetsService.fetchBookingRecords(for: date)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            return formatter.string(from: date)
        }
        
        private func formatDateForQuery(_ date: Date) -> String {
            return DateFormatters.dateFormatter.string(from: date)
        }
        
        private func parseDate(_ dateString: String) -> Date? {
            return DateFormatters.dateFormatter.date(from: dateString)
        }
        
        @MainActor
        private func updateDatesWithData(_ date: Date, withRecords records: [BookingRecord]) {
            if !records.isEmpty {
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                if !datesWithData.contains(dateComponents) {
                    datesWithData.insert(dateComponents)
                    print("✅ 更新日期數據：\(dateComponents)")
                }
            }
        }
        
        private func convertToShowtime(_ record: BookingRecord) -> MovieShowtime {
            let price = (Double(record.totalAmount) ?? 0) / (Double(record.numberOfTickets) ?? 1)
            
            // 組合日期和時間
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
            let startTime = DateFormatters.timeFormatter.date(from: record.showTime) ?? Date()
            let endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime) ?? startTime
            
            return MovieShowtime(
                id: UUID().uuidString,
                movieId: record.movieName,
                theaterId: "default",
                startTime: startTime,
                endTime: endTime,
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
                status: .onSale,
                availableSeats: 0
            )
        }
        
        private func updateShowtimesForCurrentDate(_ records: [BookingRecord]) {
            let currentDateString = formatDateForQuery(selectedDate)
            let currentDateRecords = records.filter { $0.showDate == currentDateString }
            
            if currentDateRecords.isEmpty {
                showtimes = []
                filteredShowtimes = []
            } else {
                showtimes = currentDateRecords.map(convertToShowtime)
                filterShowtimes(date: selectedDate, status: selectedStatus)
            }
        }
    }


//import Foundation
//import Combine
//
//class ShowtimeManagementViewModel: ObservableObject {
//    
//    
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
//    init(googleSheetsService: GoogleSheetsService = GoogleSheetsService()) {
//        self.googleSheetsService = googleSheetsService
//        setupBindings()
//    }
//    
//    private func setupBindings() {
//        $selectedDate
//            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
//            .sink { [weak self] date in
//                self?.loadBookingRecords(for: date)
//            }
//            .store(in: &cancellables)
//        
//        $selectedStatus
//            .sink { [weak self] status in
//                guard let self = self else { return }
//                self.filterShowtimes(date: self.selectedDate, status: status)
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func loadRecords(for date: String) async throws -> [BookingRecord] {
//        // 直接調用 async 方法，不需要使用 continuation
//        return try await googleSheetsService.fetchBookingRecords(for: date)
//    }
//    
//
//
//    
//    func loadBookingRecords(for date: Date) {
//        guard !isLoading else { return }
//        isLoading = true
//        
//        let dateString = formatDateForQuery(date)
//        
//        Task { @MainActor in
//            defer { isLoading = false }
//            do {
//                let records = try await loadRecords(for: dateString)
//                if !records.isEmpty {
//                    for record in records {
//                        if let recordDate = parseDate(record.showDate) {
//                            updateDatesWithData(recordDate, withRecords: [record])
//                        }
//                    }
//                }
//                updateShowtimesForCurrentDate(records)
//            } catch {
//                self.error = error
//                print("載入失敗：\(error)")
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
////        let startDateTime = dateFormatter.date(from: "\(record.showDate) \(record.showTime)") ?? Date()
//        let startDateTime = DateFormatters.timeFormatter.date(from: record.showTime) ?? Date()
//
//        
//        // 假設每場電影時長為 2 小時
////        let endDateTime = Calendar.current.date(byAdding: .hour, value: 2, to: startDateTime) ?? startDateTime
//        let endDateTime = Calendar.current.date(byAdding: .hour, value: 2, to: startDateTime) ?? startDateTime
//            
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
//        return DateFormatters.dateFormatter.string(from: date)
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
