import XCTest
@testable import MovieGem

final class MovieTicketViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: MovieTicketViewModel!  // system under test
    private var mockService: MockMovieTicketService!
    
    // MARK: - Test Lifecycle
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockService = MockMovieTicketService()
        sut = MovieTicketViewModel(ticketService: mockService)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Helper
    private func createSampleTicket(id: String = "1") -> MovieTicket {
        return MovieTicket(
            id: id,
            movieName: "測試電影",
            dateTime: Date(),
            seatNumber: "A1",
            price: 280.0
        )
    }
    
    // MARK: - Initial State Tests
    func testInitialState() {
        // 驗證初始狀態
        XCTAssertTrue(sut.tickets.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Fetch Tickets Tests
    func testFetchTicketsSuccess() async {
        // Given
        let expectedTicket = createSampleTicket()
        mockService.mockTickets = [expectedTicket]
        
        // When
        await sut.fetchTickets()
        
        // Then
        XCTAssertEqual(sut.tickets.count, 1)
        XCTAssertEqual(sut.tickets.first, expectedTicket)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testFetchTicketsFailure() async {
        // Given
        let expectedError = NSError(
            domain: "com.moviegem.error",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "網路連線失敗"]
        )
        mockService.mockError = expectedError
        
        // When
        await sut.fetchTickets()
        
        // Then
        XCTAssertTrue(sut.tickets.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, expectedError.localizedDescription)
    }
    
    func testLoadingStatesDuringFetch() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading states change")
        var loadingStates: [Bool] = []
        
        // When
        let cancellable = sut.$isLoading.sink { isLoading in
            loadingStates.append(isLoading)
            if loadingStates.count >= 2 {
                expectation.fulfill()
            }
        }
        
        await sut.fetchTickets()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(loadingStates, [false, true, false])
        cancellable.cancel()
    }
}

// MARK: - Mock Service
class MockMovieTicketService: MovieTicketServiceProtocol {
    var mockTickets: [MovieTicket] = []
    var mockError: Error?
    var fetchTicketsCalled = false
    
    func fetchTickets() async throws -> [MovieTicket] {
        fetchTicketsCalled = true
        
        if let error = mockError {
            throw error
        }
        return mockTickets
    }
}

// MARK: - Test Extensions
extension MovieTicket {
    static func == (lhs: MovieTicket, rhs: MovieTicket) -> Bool {
        return lhs.id == rhs.id &&
        lhs.movieName == rhs.movieName &&
        lhs.seatNumber == rhs.seatNumber &&
        abs(lhs.price - rhs.price) < 0.001
    }
}

////
////  MovieTicketViewModelTests.swift
////  MovieGemTests
////
////  Created by Lydia Lu on 2025/1/9.
////
//
//import XCTest
//@testable import MovieGem
//
//final class MovieTicketViewModelTests: XCTestCase {
//
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testExample() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        // Any test you write for XCTest can be annotated as throws and async.
//        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
//        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
//    }
//
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//
//}
