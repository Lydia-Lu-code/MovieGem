import Foundation

// 用於解碼 API 響應的結構
struct BookingRecordDTO: Codable {
    let bookingDate: String
    let movieName: String
    let showDate: String
    let showTime: String
    let numberOfTickets: String
    let ticketType: String
    let seats: String
    let totalAmount: String
    
    private enum CodingKeys: String, CodingKey {
        case bookingDate = "訂票日期"
        case movieName = "電影名稱"
        case showDate = "場次日期"
        case showTime = "場次時間"
        case numberOfTickets = "人數"
        case ticketType = "票種"
        case seats = "座位"
        case totalAmount = "總金額"
    }
    
    func toBookingRecord() -> BookingRecord {
        return BookingRecord(
            id: UUID().uuidString,
            bookingDate: bookingDate,
            movieName: movieName,
            showDate: showDate,
            showTime: showTime,
            numberOfTickets: numberOfTickets,
            ticketType: ticketType,
            seats: seats,
            totalAmount: totalAmount
        )
    }
}

struct BookingRecord: Codable, Identifiable {
    let id: String
    let bookingDate: String
    let movieName: String
    let showDate: String
    let showTime: String
    let numberOfTickets: String
    let ticketType: String
    let seats: String
    let totalAmount: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case bookingDate = "訂票日期"
        case movieName = "電影名稱"
        case showDate = "場次日期"
        case showTime = "場次時間"
        case numberOfTickets = "人數"
        case ticketType = "票種"
        case seats = "座位"
        case totalAmount = "總金額"
    }
    
    // 格式化屬性
    var formattedDate: String {
        guard let date = date else { return showDate }
        return DateFormatters.localizedDateFormatter.string(from: date)
    }
    
    var formattedTime: String {
        guard let time = DateFormatters.timeFormatter.date(from: showTime) else { return showTime }
        return DateFormatters.localizedTimeFormatter.string(from: time)
    }
    
    var formattedAmount: String {
        return "NT$ \(totalAmount)"
    }
    
    // 計算屬性
    var date: Date? {
        return DateFormatters.dateFormatter.date(from: showDate)
    }
    
    var isWeekend: Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInWeekend(date)
    }
    
    var isExpired: Bool {
        guard let showDateTime = date else { return false }
        return showDateTime < Date()
    }
    
    // 工廠方法
    static func sample() -> BookingRecord {
        return BookingRecord(
            id: UUID().uuidString,
            bookingDate: DateFormatters.dateFormatter.string(from: Date()),
            movieName: "範例電影",
            showDate: DateFormatters.dateFormatter.string(from: Date()),
            showTime: "14:30",
            numberOfTickets: "1",
            ticketType: "全票",
            seats: "A1",
            totalAmount: "280"
        )
    }
}

struct Booking: Codable, Identifiable {
    let id: String
    var showtimeId: String
    var seats: [BookingSeat]
    var totalAmount: Double
    var status: BookingStatus
    var createdAt: Date
    var paymentStatus: PaymentStatus
    
    struct BookingSeat: Codable {
        let row: Int
        let column: Int
        let type: Theater.SeatType
        let price: Double
    }
    
    enum BookingStatus: String, Codable {
        case pending = "待付款"
        case confirmed = "已確認"
        case canceled = "已取消"
        case completed = "已完成"
    }
    
    enum PaymentStatus: String, Codable {
        case pending = "待付款"
        case processing = "處理中"
        case completed = "已完成"
        case failed = "失敗"
        case refunded = "已退款"
    }
}
