// Service/MovieTicketServiceProtocol.swift
import Foundation

protocol MovieTicketServiceProtocol {
    func fetchTickets() async throws -> [MovieTicket]
    func bookTicket(_ ticket: MovieTicket) async throws -> Bool
}

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
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 模擬更複雜的預訂邏輯
        guard ticket.price > 0, !ticket.seatNumber.isEmpty else {
            throw BookingError.invalidTicket
        }
        
        // 模擬成功或失敗的情況
        let randomSuccess = Bool.random()
        
        if randomSuccess {
            print("🎫 成功預訂電影票：\(ticket.movieName) - 座位 \(ticket.seatNumber)")
            return true
        } else {
            print("❌ 預訂失敗：\(ticket.movieName)")
            throw BookingError.unavailableSeat
        }
    }

    // 可以新增自定義錯誤類型
    enum BookingError: Error {
        case unavailableSeat
        case invalidTicket
    }
    
}
