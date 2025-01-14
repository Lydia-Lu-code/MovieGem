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

////
////  MovieSheetData.swift
////  MovieGem
////
////  Created by Lydia Lu on 2025/1/13.
////
//
//import Foundation
//
//struct MovieSheetData: Codable {
//    let id: String?
//    let title: String
//    let rating: Double
//    let genre: String
//    let overview: String?
//    let releaseDate: String?
//    let posterPath: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case title
//        case rating
//        case genre
//        case overview
//        case releaseDate = "release_date"
//        case posterPath = "poster_path"
//    }
//    
//    init(id: String? = nil,
//         title: String,
//         rating: Double,
//         genre: String,
//         overview: String? = nil,
//         releaseDate: String? = nil,
//         posterPath: String? = nil) {
//        self.id = id
//        self.title = title
//        self.rating = rating
//        self.genre = genre
//        self.overview = overview
//        self.releaseDate = releaseDate
//        self.posterPath = posterPath
//    }
//}
//
//// MARK: - 擴展功能
//extension MovieSheetData {
//    var date: Date? {
//        guard let releaseDate = releaseDate else { return nil }
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        return dateFormatter.date(from: releaseDate)
//    }
//    
//    var formattedRating: String {
//        return String(format: "%.1f", rating)
//    }
//    
//    var fullPosterPath: String? {
//        guard let posterPath = posterPath else { return nil }
//        return "https://image.tmdb.org/t/p/w500\(posterPath)"
//    }
//}
//
//////
//////  MovieSheetData.swift
//////  MovieGem
//////
//////  Created by Lydia Lu on 2025/1/13.
//////
////
////import Foundation
////
////struct MovieSheetData: Codable {
////    let id: String?
////    let title: String
////    let rating: Double
////    let genre: String
////    let overview: String?
////    let releaseDate: String?
////    let posterPath: String?
////    
////    enum CodingKeys: String, CodingKey {
////        case id
////        case title
////        case rating
////        case genre
////        case overview
////        case releaseDate = "release_date"
////        case posterPath = "poster_path"
////    }
////    
////    init(id: String? = nil,
////         title: String,
////         rating: Double,
////         genre: String,
////         overview: String? = nil,
////         releaseDate: String? = nil,
////         posterPath: String? = nil) {
////        self.id = id
////        self.title = title
////        self.rating = rating
////        self.genre = genre
////        self.overview = overview
////        self.releaseDate = releaseDate
////        self.posterPath = posterPath
////    }
////    
////    init(from decoder: Decoder) throws {
////        let container = try decoder.container(keyedBy: CodingKeys.self)
////        
////        id = try container.decodeIfPresent(String.self, forKey: .id)
////        title = try container.decode(String.self, forKey: .title)
////        
////        // 處理 rating 可能是字符串的情況
////        if let ratingString = try? container.decode(String.self, forKey: .rating) {
////            rating = Double(ratingString) ?? 0.0
////        } else {
////            rating = try container.decode(Double.self, forKey: .rating)
////        }
////        
////        genre = try container.decode(String.self, forKey: .genre)
////        overview = try container.decodeIfPresent(String.self, forKey: .overview)
////        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
////        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
////    }
////    
////    func encode(to encoder: Encoder) throws {
////        var container = encoder.container(keyedBy: CodingKeys.self)
////        
////        try container.encodeIfPresent(id, forKey: .id)
////        try container.encode(title, forKey: .title)
////        try container.encode(String(rating), forKey: .rating)  // 將 rating 編碼為字符串
////        try container.encode(genre, forKey: .genre)
////        try container.encodeIfPresent(overview, forKey: .overview)
////        try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
////        try container.encodeIfPresent(posterPath, forKey: .posterPath)
////    }
////}
////
////// MARK: - 擴展功能
////extension MovieSheetData {
////    // 轉換日期字符串為 Date 對象
////    var date: Date? {
////        guard let releaseDate = releaseDate else { return nil }
////        let dateFormatter = DateFormatter()
////        dateFormatter.dateFormat = "yyyy-MM-dd"
////        return dateFormatter.date(from: releaseDate)
////    }
////    
////    // 格式化評分
////    var formattedRating: String {
////        return String(format: "%.1f", rating)
////    }
////    
////    // 完整海報URL
////    var fullPosterPath: String? {
////        guard let posterPath = posterPath else { return nil }
////        return "https://image.tmdb.org/t/p/w500\(posterPath)"
////    }
////}
////
////////
////////  MovieSheetData.swift
////////  MovieGem
////////
////////  Created by Lydia Lu on 2025/1/13.
////////
//////
//////import Foundation
//////
//////
//////// Model
//////struct MovieSheetData {
//////    let title: String
//////    let rating: Double
//////    let genre: String
//////    // 其他需要的屬性
//////}
//////
