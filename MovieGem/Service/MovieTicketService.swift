import Foundation

protocol MovieTicketServiceProtocol {
    func fetchTickets() async throws -> [MovieTicket]
    func bookTicket(_ ticket: MovieTicket) async throws -> Bool
}

class MovieTicketService: MovieTicketServiceProtocol {
    func fetchTickets() async throws -> [MovieTicket] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            MovieTicket.sample(),
            MovieTicket(
                id: UUID().uuidString,
                bookingDate: DateFormatter.dateFormatter.string(from: Date()),
                movieName: "玩具總動員",
                showtime: Date().addingTimeInterval(86400),
                numberOfTickets: 1,
                seatNumbers: ["B2"],
                price: 300.0
            )
        ]
    }
    
    func bookTicket(_ ticket: MovieTicket) async throws -> Bool {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard ticket.price > 0, !ticket.seatNumbers.isEmpty else {
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

private extension DateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}

