import Foundation
import Combine

class MovieTicketViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tickets: [MovieTicket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 添加更多計算屬性
    var hasTickets: Bool {
        !tickets.isEmpty
    }
    
    var unexpiredTickets: [MovieTicket] {
        tickets.filter { !$0.isExpired }
    }
    
    var totalTicketValue: Double {
        tickets.reduce(0) { $0 + $1.price }
    }
    
    // 添加 cancellables 屬性
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service
    private let ticketService: MovieTicketServiceProtocol
    
    // MARK: - Initialization
    init(ticketService: MovieTicketServiceProtocol) {
        self.ticketService = ticketService
    }
    
    // MARK: - Data Fetching Method
    @MainActor
    func fetchTickets() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            tickets = try await ticketService.fetchTickets()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Additional Methods
    @MainActor
    func bookTicket(_ ticket: MovieTicket) async -> Bool {
        do {
            return try await ticketService.bookTicket(ticket)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

