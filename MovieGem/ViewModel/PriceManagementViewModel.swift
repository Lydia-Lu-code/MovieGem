//
//  PriceManagementViewModel.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import Foundation

class PriceManagementViewModel {
    // MARK: - Publishers
    @Published var prices: [ShowtimePrice] = []
    @Published var discounts: [PriceDiscount] = []
    @Published var selectedSegmentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Services
    private let priceService: PriceServiceProtocol
    
    // MARK: - Initialization
    init(priceService: PriceServiceProtocol = PriceService()) {
        self.priceService = priceService
    }
    
    // MARK: - Data Methods
    func loadData() {
        isLoading = true
        
        Task {
            do {
                async let pricesResult = priceService.fetchPrices()
                async let discountsResult = priceService.fetchDiscounts()
                
                let (fetchedPrices, fetchedDiscounts) = await (try pricesResult, try discountsResult)
                
                await MainActor.run {
                    self.prices = fetchedPrices
                    self.discounts = fetchedDiscounts
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
    
    func addPrice(_ price: ShowtimePrice) async throws {
        let newPrice = try await priceService.addPrice(price)
        await MainActor.run {
            prices.append(newPrice)
        }
    }
    
    func updatePrice(_ price: ShowtimePrice) async throws {
        let updatedPrice = try await priceService.updatePrice(price)
        await MainActor.run {
            if let index = prices.firstIndex(where: { $0.basePrice == price.basePrice }) {
                prices[index] = updatedPrice
            }
        }
    }
    
    func deletePrice(at index: Int) async throws {
        let price = prices[index]
        try await priceService.deletePrice(price)
        await MainActor.run {
            prices.remove(at: index)
        }
    }
    
    func addDiscount(_ discount: PriceDiscount) async throws {
        let newDiscount = try await priceService.addDiscount(discount)
        await MainActor.run {
            discounts.append(newDiscount)
        }
    }
    
    func updateDiscount(_ discount: PriceDiscount) async throws {
        let updatedDiscount = try await priceService.updateDiscount(discount)
        await MainActor.run {
            if let index = discounts.firstIndex(where: { $0.id == discount.id }) {
                discounts[index] = updatedDiscount
            }
        }
    }
    
    func deleteDiscount(at index: Int) async throws {
        let discount = discounts[index]
        try await priceService.deleteDiscount(discount)
        await MainActor.run {
            discounts.remove(at: index)
        }
    }
    
    // MARK: - Helper Methods
    func calculateDiscountedPrice(_ price: ShowtimePrice, with discount: PriceDiscount) -> Double {
        switch discount.type {
        case .percentage:
            return price.basePrice * discount.value
        case .fixedAmount:
            return max(0, price.basePrice - discount.value)
        }
    }
}
