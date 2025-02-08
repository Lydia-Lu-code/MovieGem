//
//  MovieAdminViewModel.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/2/8.
//

import Foundation
import Combine

class MovieAdminViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var isShowingAlert = false
    @Published var errorMessage: String?
    
    private let sheetsService: MovieBookingDataService
    
    init(sheetsService: MovieBookingDataService = GoogleSheetsService()) {
        self.sheetsService = sheetsService
    }
    
    func fetchMovieData(for date: String) async {
        do {
            let records = try await sheetsService.fetchMovieBookings()
            
            if records.isEmpty {
                errorMessage = "沒有訂位"
            } else {
                errorMessage = nil
            }
            
            await MainActor.run {
                // 處理成功的情況
                print("已獲取資料數量：\(records.count)")
//                print("篩選日期：\(date)")
            }
        } catch {
            await MainActor.run {
                errorMessage = "加載失敗"
//                print("載入錯誤：\(error)")
            }
        }
    }
    
    func getActionButtonTitle(for index: Int) -> String {
        switch index {
        case 0: return "新增影廳"
        case 1: return "新增訂票"
        case 2: return "新增場次"
        case 3: return "新增票價"
        default: return "操作"
        }
    }
}
