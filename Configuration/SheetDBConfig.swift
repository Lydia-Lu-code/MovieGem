//
//  GoogleSheetsConfig.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/13.
//

import Foundation

struct SheetDBConfig {
    // SheetDB API endpoint
    static let apiEndpoint = "https://sheetdb.io/api/v1/gwog7qdzdkusm"
    
    // 如果需要添加其他設定，可以在這裡擴充
    static let timeout: TimeInterval = 30.0
    static let maxRetries = 3
}
