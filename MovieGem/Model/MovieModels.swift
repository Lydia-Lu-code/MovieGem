import Foundation

enum TheaterStatus: String, CaseIterable, Codable {
    case active = "營業中"
    case maintenance = "維護中"
    case closed = "暫停使用"
}

struct Theater: Codable, Identifiable {
    let id: String
    var name: String
    var capacity: Int
    var type: TheaterType
    var status: TheaterStatus
    var seatLayout: [[SeatType]]
    
    enum TheaterType: String, Codable, CaseIterable {
        case standard = "標準廳"
        case imax = "IMAX"
        case vip = "VIP廳"
        case fourDX = "4DX"
    }
    
    enum SeatType: String, Codable {
        case normal = "一般座位"
        case vip = "VIP座位"
        case handicapped = "無障礙座位"
        case empty = "空位"
    }
    
    // 計算可用座位數
    var availableSeats: Int {
        return seatLayout.flatMap { $0 }.filter { $0 == .empty }.count
    }
    
    // 是否可以使用
    var isAvailable: Bool {
        return status == .active
    }
}

struct MovieShowtime: Codable, Identifiable {
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
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var isOnSale: Bool {
        return status == .onSale
    }
    
    func calculateDiscountedPrice(with discount: PriceDiscount) -> Double {
        switch discount.type {
        case .percentage:
            return price.basePrice * (1 - discount.value)
        case .fixedAmount:
            return max(0, price.basePrice - discount.value)
        }
    }
}

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

struct PriceDiscount: Codable, Identifiable {
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


//import Foundation
//
//enum TheaterStatus: String, CaseIterable, Codable {
//    case active = "營業中"
//    case maintenance = "維護中"
//    case closed = "暫停使用"
//}
//
//struct Theater: Codable, Identifiable {
//    let id: String
//    var name: String
//    var capacity: Int
//    var type: TheaterType
//    var status: TheaterStatus
//    var seatLayout: [[SeatType]]
//    
//    enum TheaterType: String, Codable, CaseIterable {
//        case standard = "標準廳"
//        case imax = "IMAX"
//        case vip = "VIP廳"
//        case fourDX = "4DX"
//    }
//    
//    enum SeatType: String, Codable {
//        case normal = "一般座位"
//        case vip = "VIP座位"
//        case handicapped = "無障礙座位"
//        case empty = "空位"
//    }
//    
//    // 計算可用座位數
//    var availableSeats: Int {
//        return seatLayout.flatMap { $0 }.filter { $0 == .empty }.count
//    }
//    
//    // 是否可以使用
//    var isAvailable: Bool {
//        return status == .active
//    }
//}
//
//struct MovieShowtime: Codable, Identifiable {
//    let id: String
//    var movieId: String
//    var theaterId: String
//    var startTime: Date
//    var endTime: Date
//    var price: ShowtimePrice
//    var status: ShowtimeStatus
//    var availableSeats: Int
//    
//    enum ShowtimeStatus: String, Codable {
//        case scheduled = "預定"
//        case onSale = "售票中"
//        case almostFull = "即將額滿"
//        case soldOut = "已售完"
//        case canceled = "已取消"
//    }
//    
//    var duration: TimeInterval {
//        return endTime.timeIntervalSince(startTime)
//    }
//    
//    var isOnSale: Bool {
//        return status == .onSale
//    }
//    
//    func calculateDiscountedPrice(with discount: PriceDiscount) -> Double {
//        switch discount.type {
//        case .percentage:
//            return price.basePrice * (1 - discount.value)
//        case .fixedAmount:
//            return max(0, price.basePrice - discount.value)
//        }
//    }
//}
//
//struct ShowtimePrice: Codable {
//    var basePrice: Double
//    var weekendPrice: Double?
//    var holidayPrice: Double?
//    var studentPrice: Double?
//    var seniorPrice: Double?
//    var childPrice: Double?
//    var vipPrice: Double?
//    
//    var discounts: [PriceDiscount]
//}
//
//struct PriceDiscount: Codable, Identifiable {
//    let id: String
//    var name: String
//    var type: DiscountType
//    var value: Double
//    var startDate: Date
//    var endDate: Date
//    var description: String
//    
//    enum DiscountType: String, Codable {
//        case percentage = "折扣百分比"
//        case fixedAmount = "固定金額"
//    }
//}
//
//struct Booking: Codable, Identifiable {
//    let id: String
//    var showtimeId: String
//    var seats: [BookingSeat]
//    var totalAmount: Double
//    var status: BookingStatus
//    var createdAt: Date
//    var paymentStatus: PaymentStatus
//    
//    struct BookingSeat: Codable {
//        let row: Int
//        let column: Int
//        let type: Theater.SeatType
//        let price: Double
//    }
//    
//    enum BookingStatus: String, Codable {
//        case pending = "待付款"
//        case confirmed = "已確認"
//        case canceled = "已取消"
//        case completed = "已完成"
//    }
//    
//    enum PaymentStatus: String, Codable {
//        case pending = "待付款"
//        case processing = "處理中"
//        case completed = "已完成"
//        case failed = "失敗"
//        case refunded = "已退款"
//    }
//}
//
