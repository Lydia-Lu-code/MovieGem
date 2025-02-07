//
//  BookingRecord.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/24.
//

import Foundation

struct BookingRecord: Codable {
    let date: String
    let movieName: String
    let showDate: String
    let showTime: String
    let numberOfTickets: String
    let ticketType: String
    let seats: String
    let totalAmount: String
    
    private enum CodingKeys: String, CodingKey {
        case date = "訂票日期"
        case movieName = "電影名稱"
        case showDate = "場次日期"
        case showTime = "場次時間"
        case numberOfTickets = "人數"
        case ticketType = "票種"
        case seats = "座位"
        case totalAmount = "總金額"
    }
}

// 擴展以增加便利功能
extension BookingRecord {
    var formattedDate: String {
        DateFormatter.localizedString(from: DateFormatter.dateFormatter.date(from: showDate) ?? Date(), dateStyle: .medium, timeStyle: .none)
    }
    
    var formattedTime: String {
        DateFormatter.localizedString(from: DateFormatter.timeFormatter.date(from: showTime) ?? Date(), dateStyle: .none, timeStyle: .short)
    }
}

private extension DateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
