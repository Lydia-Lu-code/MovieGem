//
//  MovieSheetData.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/13.
//

import Foundation

struct MovieSheetData: Codable {
    let bookingDate: String
    let movieName: String
    let showDate: String
    let showTime: String
    let numberOfPeople: String
    let ticketType: String
    let seats: String
    let totalAmount: String
    
    enum CodingKeys: String, CodingKey {
        case bookingDate = "訂票日期"
        case movieName = "電影名稱"
        case showDate = "場次日期"
        case showTime = "場次時間"
        case numberOfPeople = "人數"
        case ticketType = "票種"
        case seats = "座位"
        case totalAmount = "總金額"
    }
}

// MARK: - 擴展功能
extension MovieSheetData {
    var date: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return dateFormatter.date(from: showDate)
    }
    
    var formattedDate: String {
        return showDate
    }
    
    var formattedTime: String {
        return showTime
    }
    
    var formattedAmount: String {
        return "NT$ \(totalAmount)"
    }
}

