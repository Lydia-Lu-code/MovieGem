import Foundation

struct MovieTicketViewModel {
    private let bookingRecord: BookingRecord
    
    init(bookingRecord: BookingRecord) {
        self.bookingRecord = bookingRecord
    }
    
    // 基本屬性
    var id: String { bookingRecord.id }
    var movieName: String { bookingRecord.movieName }
    var showDate: String { bookingRecord.showDate }
    var showTime: String { bookingRecord.showTime }
    var numberOfTickets: Int { Int(bookingRecord.numberOfTickets) ?? 0 }
    var seatNumbers: [String] { bookingRecord.seats.components(separatedBy: ", ") }
    var price: Double { Double(bookingRecord.totalAmount) ?? 0.0 }
    
    // 格式化屬性
    var formattedPrice: String { "NT$ \(bookingRecord.totalAmount)" }
    var formattedDate: String { bookingRecord.formattedDate }
    var formattedTime: String { bookingRecord.formattedTime }
    
    // 計算屬性
    var isExpired: Bool {
        guard let date = bookingRecord.date else { return false }
        return date < Date()
    }
    
    // 工廠方法
    static func sample() -> MovieTicketViewModel {
        return MovieTicketViewModel(bookingRecord: BookingRecord.sample())
    }
}
