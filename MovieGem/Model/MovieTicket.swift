import Foundation

struct MovieTicket: Identifiable, Equatable, Codable {
    let id: String
    let bookingDate: String
    let movieName: String
    let showtime: Date
    let numberOfTickets: Int
    let seatNumbers: [String]
    let price: Double
    
    var formattedPrice: String {
        return String(format: "NT$ %.0f", price)
    }
    
    var isExpired: Bool {
        return showtime < Date()
    }
    
    static func sample() -> MovieTicket {
        MovieTicket(
            id: UUID().uuidString,
            bookingDate: DateFormatter.dateFormatter.string(from: Date()),
            movieName: "範例電影",
            showtime: Date(),
            numberOfTickets: 1,
            seatNumbers: ["A1"],
            price: 280.0
        )
    }
}

private extension DateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}

