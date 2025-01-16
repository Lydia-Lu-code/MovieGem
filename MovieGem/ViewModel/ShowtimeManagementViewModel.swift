import Foundation
import Combine

class ShowtimeManagementViewModel: ObservableObject, MovieAdminViewModelProtocol {
    // MARK: - Published Properties
    @Published var showtimes: [MovieShowtime] = []
    @Published var theaters: [Theater] = []
    @Published var isLoading = false
    @Published var selectedDate: Date = Date()
    @Published var selectedStatus: MovieShowtime.ShowtimeStatus? = nil
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        
        // 模擬載入場次和影廳數據
        theaters = [
            Theater(id: "1", name: "第一廳", capacity: 120, type: .standard,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
            Theater(id: "2", name: "IMAX廳", capacity: 180, type: .imax,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12))
        ]
        
        showtimes = [
            MovieShowtime(
                id: "1",
                movieId: "movie1",
                theaterId: "1",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(3600 * 3),
                price: ShowtimePrice(
                    basePrice: 280,
                    weekendPrice: nil,
                    holidayPrice: nil,
                    studentPrice: nil,
                    seniorPrice: nil,
                    childPrice: nil,
                    vipPrice: nil,
                    discounts: []
                ),
                status: .onSale,
                availableSeats: 80
            ),
            MovieShowtime(
                id: "2",
                movieId: "movie2",
                theaterId: "2",
                startTime: Date().addingTimeInterval(3600 * 4),
                endTime: Date().addingTimeInterval(3600 * 6),
                price: ShowtimePrice(
                    basePrice: 380,
                    weekendPrice: nil,
                    holidayPrice: nil,
                    studentPrice: nil,
                    seniorPrice: nil,
                    childPrice: nil,
                    vipPrice: nil,
                    discounts: []
                ),
                status: .almostFull,
                availableSeats: 20
            )
        ]
        
        isLoading = false
    }
    
    // MARK: - Showtime Management Methods
    func addShowtime(movieId: String, theaterId: String, startTime: Date, endTime: Date, price: ShowtimePrice) {
        let newShowtime = MovieShowtime(
            id: UUID().uuidString,
            movieId: movieId,
            theaterId: theaterId,
            startTime: startTime,
            endTime: endTime,
            price: price,
            status: .onSale,
            availableSeats: getAvailableSeats(for: theaterId)
        )
        
        showtimes.append(newShowtime)
    }
    
    func removeShowtime(at index: Int) {
        showtimes.remove(at: index)
    }
    
    func updateShowtimeStatus(at index: Int, to status: MovieShowtime.ShowtimeStatus) {
        showtimes[index].status = status
    }
    
    // MARK: - Filtering Methods
    func filteredShowtimes() -> [MovieShowtime] {
        showtimes.filter { showtime in
            let calendar = Calendar.current
            let isSameDay = calendar.isDate(showtime.startTime, inSameDayAs: selectedDate)
            
            let statusMatch = selectedStatus == nil || showtime.status == selectedStatus
            
            return isSameDay && statusMatch
        }
    }
    
    // MARK: - Helper Methods
    private func getAvailableSeats(for theaterId: String) -> Int {
        guard let theater = theaters.first(where: { $0.id == theaterId }) else {
            return 0
        }
        return theater.capacity
    }
}
