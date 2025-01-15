// Service/MovieTicketServiceProtocol.swift
import Foundation

protocol MovieTicketServiceProtocol {
    func fetchTickets() async throws -> [MovieTicket]
    func bookTicket(_ ticket: MovieTicket) async throws -> Bool
}

// Service/MovieTicketService.swift
import Foundation

class MovieTicketService: MovieTicketServiceProtocol {
    func fetchTickets() async throws -> [MovieTicket] {
        // 模擬網路請求延遲
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 回傳模擬資料
        return [
            MovieTicket.sample(),
            MovieTicket(id: UUID().uuidString,
                       movieName: "玩具總動員",
                       dateTime: Date().addingTimeInterval(86400),
                       seatNumber: "B2",
                       price: 300.0)
        ]
    }
    
    func bookTicket(_ ticket: MovieTicket) async throws -> Bool {
        // 模擬網路請求延遲
        try await Task.sleep(nanoseconds: 1_000_000_000)
        // 模擬成功預訂
        return true
    }
}
