import Foundation
import Combine

class MovieSheetViewModel: ObservableObject {
    @Published var movies: [MovieSheetData] = []
    @Published var filteredMovies: [MovieSheetData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let sheetsService: GoogleSheetsServiceProtocol
        
        init(sheetsService: GoogleSheetsServiceProtocol) {
            self.sheetsService = sheetsService
        }
        
        @MainActor
        func fetchMovieData() {
            guard !isLoading else { return }
            
            isLoading = true
            error = nil
            
            Task {
                do {
                    movies = try await sheetsService.fetchData(for: nil)
                    isLoading = false
                } catch {
                    self.error = error
                    isLoading = false
                }
            }
        }
    
    // 計算屬性
    var totalBookings: Int {
        movies.count
    }
    
    var totalAmount: Double {
        movies.compactMap { Double($0.totalAmount) }.reduce(0, +)
    }
    
    var cancellables = Set<AnyCancellable>()
    
    // 移動 filterMoviesByDate 從 ViewController 到 ViewModel
    func filterMoviesByDate(_ date: Date) {
        let calendar = Calendar.current
        movies = movies.filter { movie in
            guard let movieDate = movie.date else { return false }
            return calendar.isDate(movieDate, inSameDayAs: date)
        }
    }
    
    // 新增錯誤訊息處理
    func getErrorMessage(_ error: Error) -> String {
        return error.localizedDescription
    }
    
    
    func filterMovies(by movieName: String) -> [MovieSheetData] {
        movies.filter { $0.movieName.contains(movieName) }
    }
    
    func sortMoviesByDate() -> [MovieSheetData] {
        movies.sorted {
            guard let date1 = $0.date, let date2 = $1.date else { return false }
            return date1 < date2
        }
    }
    
    func filterByDate(_ date: Date) {
        let calendar = Calendar.current
        filteredMovies = movies.filter { movie in
            guard let movieDate = movie.date else { return false }
            return calendar.isDate(movieDate, inSameDayAs: date)
        }
    }
    

}

