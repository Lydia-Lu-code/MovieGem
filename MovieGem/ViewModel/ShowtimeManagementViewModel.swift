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
    
    
    // MARK: - Public Methods
    @MainActor
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
                print("載入的記錄數：\(records.count)")
                print("篩選日期：\(dateString)")
                
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
        
        // 使用完整的日期和時間
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        
        // 組合完整的日期時間字符串
        let fullDateTimeString = "\(record.showDate) \(record.showTime)"
        let startTime = dateFormatter.date(from: fullDateTimeString) ?? Date()
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
        
        // 移除日期前導零，以支持兩種日期格式
        let currentDateStringWithoutLeadingZero = currentDateString.replacingOccurrences(of: "^0", with: "", options: .regularExpression)
        
        let currentDateRecords = records.filter { record in
            // 比對包含前導零和不包含前導零的兩種日期格式
            record.showDate == currentDateString ||
            record.showDate == currentDateStringWithoutLeadingZero
        }
        
        if currentDateRecords.isEmpty {
            showtimes = []
            filteredShowtimes = []
        } else {
            showtimes = currentDateRecords.map(convertToShowtime)
            filterShowtimes(date: selectedDate, status: selectedStatus)
        }
        
        print("當前日期：\(currentDateString)")
        print("篩選出的紀錄數：\(currentDateRecords.count)")
    }
    
    }

