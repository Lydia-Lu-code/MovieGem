//
//  MovieSheetCellViewModel.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/2/8.
//

import Foundation

struct MovieSheetCellViewModel {
    private let bookingRecord: BookingRecord
    
    init(bookingRecord: BookingRecord) {
        self.bookingRecord = bookingRecord
    }
    
    var movieNameText: String {
        "🎬 \(bookingRecord.movieName)"
    }
    
    var dateTimeText: String {
        "📅 \(bookingRecord.showDate) \(bookingRecord.showTime)"
    }
    
    var seatsText: String {
        "💺 座位：\(bookingRecord.seats) (\(bookingRecord.ticketType))"
    }
    
    var amountText: String {
        "💰 NT$ \(bookingRecord.totalAmount)"
    }
}
