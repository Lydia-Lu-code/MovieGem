import Foundation
import Combine

class MovieSheetViewModel: ObservableObject {
    @Published var movies: [BookingRecord] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    internal let sheetsService: MovieBookingDataService
    
    init(sheetsService: MovieBookingDataService = GoogleSheetsService()) {
        self.sheetsService = sheetsService
    }
    
    func loadData(for date: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let records = try await sheetsService.fetchBookingRecords(for: date)
                await MainActor.run {
                    self.movies = records
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
    
    // 輔助方法
    func movieExists(for date: String) -> Bool {
        return !movies.filter { $0.showDate == date }.isEmpty
    }
    
    func getTotalAmount() -> Double {
        return movies.compactMap { Double($0.totalAmount) }.reduce(0, +)
    }
}

//import Foundation
//import Combine
//
//
//class MovieSheetViewModel: ObservableObject {
////    @Published var bookingRecords: [BookingRecord] = []
//    @Published var movies: [BookingRecord] = []
//    @Published var isLoading = false
//    @Published var error: Error?
//    
//    let sheetsService: MovieBookingDataService
//    
//    init(sheetsService: MovieBookingDataService = GoogleSheetsService()) {
//        self.sheetsService = sheetsService
//    }
//    
//    func loadData(for date: String) {
//        isLoading = true
//        
//        Task {
//            do {
//                let records = try await sheetsService.fetchBookingRecords(for: date)
//                await MainActor.run {
//                    self.movies = records
//                    self.isLoading = false
//                }
//            } catch {
//                await MainActor.run {
//                    self.error = error
//                    self.isLoading = false
//                }
//            }
//        }
//    }
//}
