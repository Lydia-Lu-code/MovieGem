// Model/MovieTicket.swift
import Foundation

struct MovieTicket: Identifiable, Equatable {
    let id: String
    let movieName: String
    let dateTime: Date
    let seatNumber: String
    let price: Double
    
    // 方便測試用的初始化方法
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
