//
//  TheaterDetailViewModel.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/15.
//

import Foundation
import Combine

class TheaterDetailViewModel: ObservableObject {
    @Published var movies: [MovieSheetData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let theater: Theater
    private let sheetsService: GoogleSheetsServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    init(theater: Theater, sheetsService: GoogleSheetsServiceProtocol) {
        self.theater = theater
        self.sheetsService = sheetsService
    }
    
    func fetchMovieData() {
        isLoading = true
        
        Task {
            do {
                let fetchedMovies = try await sheetsService.fetchData()
                
                // 可以在這裡根據影廳篩選相關的電影
                let filteredMovies = fetchedMovies.filter { $0.seats.contains(theater.name) }
                
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
    
    // 計算屬性
    var theaterInfo: String {
        """
        影廳名稱: \(theater.name)
        座位數: \(theater.capacity)
        類型: \(theater.type.rawValue)
        狀態: \(theater.status.rawValue)
        """
    }
}
