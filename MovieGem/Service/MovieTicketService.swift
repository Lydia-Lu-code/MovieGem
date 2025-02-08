import Foundation

// 更新協議定義
protocol MovieTicketServiceProtocol {
    func fetchTickets() async throws -> [BookingRecord]
    func bookTicket(_ booking: BookingRecord) async throws -> Bool
}

class MovieTicketService: MovieTicketServiceProtocol {
    func fetchTickets() async throws -> [BookingRecord] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 使用 BookingRecord.sample() 創建範例數據
        return [
            BookingRecord.sample(),
            BookingRecord(
                id: UUID().uuidString,
                bookingDate: DateFormatters.dateFormatter.string(from: Date()),
                movieName: "玩具總動員",
                showDate: DateFormatters.dateFormatter.string(from: Date()),
                showTime: "14:30",
                numberOfTickets: "1",
                ticketType: "全票",
                seats: "B2",
                totalAmount: "300"
            )
        ]
    }
    
    func bookTicket(_ booking: BookingRecord) async throws -> Bool {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 驗證票務資訊
        guard let amount = Double(booking.totalAmount),
              amount > 0,
              !booking.seats.isEmpty else {
            throw BookingError.invalidTicket
        }
        
        let randomSuccess = Bool.random()
        if randomSuccess {
           return true
        } else {
           throw BookingError.unavailableSeat
        }
    }

    enum BookingError: Error {
        case unavailableSeat
        case invalidTicket
    }
}
