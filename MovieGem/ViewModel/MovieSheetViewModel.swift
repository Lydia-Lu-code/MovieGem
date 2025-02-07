import Foundation
import Combine


class MovieSheetViewModel: ObservableObject {
    @Published var movies: [MovieSheetData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let sheetsService: MovieBookingDataService
    
    init(sheetsService: MovieBookingDataService = GoogleSheetsService() as! MovieBookingDataService) {
        self.sheetsService = sheetsService
    }
    
}

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
