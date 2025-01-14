import Foundation

class MovieSheetViewModel: ObservableObject {
    @Published var movies: [MovieSheetData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let sheetsService: GoogleSheetsServiceProtocol
    
    init(sheetsService: GoogleSheetsServiceProtocol) {
        self.sheetsService = sheetsService
    }
    
    // MovieSheetViewModel.swift
    @MainActor
    func fetchMovieData() {
        print("🟡 開始獲取資料")
        guard !isLoading else {
            print("❌ 已在載入中，跳過")
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                print("🟡 正在呼叫 API...")
                movies = try await sheetsService.fetchData()
                print("✅ 成功獲取資料，數量：\(movies.count)")
            } catch {
                print("❌ 發生錯誤：\(error)")
                self.error = error
            }
            isLoading = false
            print("🟡 載入完成")
        }
    }
    
}

