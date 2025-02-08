import Foundation
import Combine


class MovieSheetViewModel: ObservableObject {
//    @Published var bookingRecords: [BookingRecord] = []
    @Published var movies: [BookingRecord] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let sheetsService: MovieBookingDataService
    
    init(sheetsService: MovieBookingDataService = GoogleSheetsService()) {
        self.sheetsService = sheetsService
    }
    
    func loadData(for date: String) {
        isLoading = true
        
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
}
