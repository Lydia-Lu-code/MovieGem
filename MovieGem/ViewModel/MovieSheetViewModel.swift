import Foundation
import Combine

class MovieSheetViewModel: ObservableObject {
    @Published var movies: [MovieSheetData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // 計算屬性
    var totalBookings: Int {
        movies.count
    }
    
    var totalAmount: Double {
        movies.compactMap { Double($0.totalAmount) }.reduce(0, +)
    }
    
    var cancellables = Set<AnyCancellable>()
    
    private let sheetsService: GoogleSheetsServiceProtocol
    
    init(sheetsService: GoogleSheetsServiceProtocol) {
        self.sheetsService = sheetsService
    }
    
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
                // 使用 self 明確指派
                self.error = error
                isLoading = false
            }
            isLoading = false
            print("🟡 載入完成")
        }
    }
    
    // 添加篩選和排序方法
    func filterMovies(by movieName: String) -> [MovieSheetData] {
        movies.filter { $0.movieName.contains(movieName) }
    }
    
    func sortMoviesByDate() -> [MovieSheetData] {
        movies.sorted {
            guard let date1 = $0.date, let date2 = $1.date else { return false }
            return date1 < date2
        }
    }
}

