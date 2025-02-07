import Foundation
import Combine

class TheaterDetailViewModel: ObservableObject {
    @Published var movies: [MovieSheetData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let theater: Theater
    private let sheetsService: MovieBookingDataService
    var cancellables = Set<AnyCancellable>()
    
    init(theater: Theater, sheetsService: MovieBookingDataService = GoogleSheetsService() as! MovieBookingDataService) {
        self.theater = theater
        self.sheetsService = sheetsService
    }
    
    func fetchMovieData(for date: Date = Date()) {
        isLoading = true
        let dateString = DateFormatter.dateFormatter.string(from: date)
        
        Task {
            do {
//                let records = try await sheetsService.fetchMovieBookings(for: dateString)
                let records = try await sheetsService.fetchMovieBookings()
                let movieData = records.map { record in
                    MovieSheetData(
                        bookingDate: record.date,
                        movieName: record.movieName,
                        showDate: record.showDate,
                        showTime: record.showTime,
                        numberOfPeople: record.numberOfTickets,
                        ticketType: record.ticketType,
                        seats: record.seats,
                        totalAmount: record.totalAmount
                    )
                }
                let filteredMovies = movieData.filter { $0.seats.contains(theater.name) }
                
                await MainActor.run {
                    self.movies = filteredMovies
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    var theaterInfo: String {
        """
        影廳名稱: \(theater.name)
        座位數: \(theater.capacity)
        類型: \(theater.type.rawValue)
        狀態: \(theater.status.rawValue)
        """
    }

    func getMovieCellText(_ movie: MovieSheetData) -> String {
        return """
        電影: \(movie.movieName)
        日期: \(movie.showDate)
        時間: \(movie.showTime)
        座位: \(movie.seats)
        """
    }
}

private extension DateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}
