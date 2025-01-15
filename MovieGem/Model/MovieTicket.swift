import Foundation

struct MovieTicket: Identifiable, Equatable, Codable {
    let id: String
    let movieName: String
    let dateTime: Date
    let seatNumber: String
    let price: Double
    
    var formattedPrice: String {
        return String(format: "NT$ %.0f", price)
    }
    
    var isExpired: Bool {
        return dateTime < Date()
    }
    
    static func sample() -> MovieTicket {
        MovieTicket(
            id: UUID().uuidString,
            movieName: "範例電影",
            dateTime: Date(),
            seatNumber: "A1",
            price: 280.0
        )
    }
}
