//
//  MovieAdmin.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import Foundation

enum TheaterStatus: String, CaseIterable {   // 加入 CaseIterable 協議
    case active = "營業中"
    case maintenance = "維護中"
    case closed = "暫停使用"
}

// MARK: - 影廳模型
struct Theater: Codable {
    let id: String
    var name: String
    var capacity: Int
    var type: TheaterType
    var status: TheaterStatus
    var seatLayout: [[SeatType]]
    
    enum TheaterType: String, Codable, CaseIterable {  // 添加 CaseIterable
        case standard = "標準廳"
        case imax = "IMAX"
        case vip = "VIP廳"
        case fourDX = "4DX"
    }
    
    enum TheaterStatus: String, Codable, CaseIterable {  // 添加 CaseIterable
        case active = "營業中"
        case maintenance = "維護中"
        case closed = "暫停使用"
    }
    
    enum SeatType: String, Codable {
        case normal = "一般座位"
        case vip = "VIP座位"
        case handicapped = "無障礙座位"
        case empty = "空位"
    }
}



// MARK: - 電影場次模型
struct MovieShowtime: Codable {
    let id: String
    var movieId: String
    var theaterId: String
    var startTime: Date
    var endTime: Date
    var price: ShowtimePrice
    var status: ShowtimeStatus
    var availableSeats: Int
    
    enum ShowtimeStatus: String, Codable {
        case scheduled = "預定"
        case onSale = "售票中"
        case almostFull = "即將額滿"
        case soldOut = "已售完"
        case canceled = "已取消"
    }
}

// MARK: - 票價設定模型
struct ShowtimePrice: Codable {
    var basePrice: Double
    var weekendPrice: Double?
    var holidayPrice: Double?
    var studentPrice: Double?
    var seniorPrice: Double?
    var childPrice: Double?
    var vipPrice: Double?
    
    var discounts: [PriceDiscount]
}

struct PriceDiscount: Codable {
    let id: String
    var name: String
    var type: DiscountType
    var value: Double
    var startDate: Date
    var endDate: Date
    var description: String
    
    enum DiscountType: String, Codable {
        case percentage = "折扣百分比"
        case fixedAmount = "固定金額"
    }
}

// MARK: - 訂票模型
struct Booking: Codable {
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
