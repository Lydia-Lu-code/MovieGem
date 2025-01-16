import Foundation
import Combine

class TheaterManagementViewModel: ObservableObject, MovieAdminViewModelProtocol {
    // MARK: - Published Properties
    @Published var theaters: [Theater] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        
        // 模擬數據載入，實際情況可能是從服務獲取
        theaters = [
            Theater(id: "1", name: "第一影廳", capacity: 120, type: .standard,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
            Theater(id: "2", name: "IMAX影廳", capacity: 180, type: .imax,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12)),
            Theater(id: "3", name: "VIP影廳", capacity: 60, type: .vip,
                   status: .maintenance, seatLayout: Array(repeating: Array(repeating: .vip, count: 8), count: 8))
        ]
        
        isLoading = false
    }
    
    // MARK: - Theater Management Methods
    func addTheater(name: String, capacity: Int, type: Theater.TheaterType) {
        let newTheater = Theater(
            id: UUID().uuidString,
            name: name,
            capacity: capacity,
            type: type,
            status: .active,
            seatLayout: Array(repeating: Array(repeating: .normal, count: Int(sqrt(Double(capacity)))),
                            count: Int(sqrt(Double(capacity))))
        )
        
        theaters.append(newTheater)
    }
    
    func removeTheater(at index: Int) {
        theaters.remove(at: index)
    }
    
    func updateTheaterStatus(at index: Int, to status: TheaterStatus) {
        theaters[index].status = status
    }
}
