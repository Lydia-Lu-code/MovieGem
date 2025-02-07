//
//  PriceService.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import Foundation


// MARK: - Services
protocol PriceServiceProtocol {
    func fetchPrices() async throws -> [ShowtimePrice]
    func fetchDiscounts() async throws -> [PriceDiscount]
    func addPrice(_ price: ShowtimePrice) async throws -> ShowtimePrice
    func updatePrice(_ price: ShowtimePrice) async throws -> ShowtimePrice
    func deletePrice(_ price: ShowtimePrice) async throws
    func addDiscount(_ discount: PriceDiscount) async throws -> PriceDiscount
    func updateDiscount(_ discount: PriceDiscount) async throws -> PriceDiscount
    func deleteDiscount(_ discount: PriceDiscount) async throws
}

class PriceService: PriceServiceProtocol {
    // 模擬網絡請求延遲
    private func simulateNetworkDelay() async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    }
    
    func fetchPrices() async throws -> [ShowtimePrice] {
        try await simulateNetworkDelay()
        // 模擬數據
        return [
            ShowtimePrice(
                basePrice: 280,
                weekendPrice: 320,
                holidayPrice: 320,
                studentPrice: 240,
                seniorPrice: 200,
                childPrice: 200,
                vipPrice: 400,
                discounts: []
            )
        ]
    }
    
    func fetchDiscounts() async throws -> [PriceDiscount] {
        try await simulateNetworkDelay()
        // 模擬數據
        return [
            PriceDiscount(
                id: "1",
                name: "早鳥優惠",
                type: .percentage,
                value: 0.8,
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 30),
                description: "早場次享8折優惠"
            ),
            PriceDiscount(
                id: "2",
                name: "學生證優惠",
                type: .fixedAmount,
                value: 40,
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 90),
                description: "憑學生證現省40元"
            )
        ]
    }
    
    func addPrice(_ price: ShowtimePrice) async throws -> ShowtimePrice {
        try await simulateNetworkDelay()
        return price // 模擬添加成功
    }
    
    func updatePrice(_ price: ShowtimePrice) async throws -> ShowtimePrice {
        try await simulateNetworkDelay()
        return price // 模擬更新成功
    }
    
    func deletePrice(_ price: ShowtimePrice) async throws {
        try await simulateNetworkDelay()
        // 模擬刪除成功
    }
    
    func addDiscount(_ discount: PriceDiscount) async throws -> PriceDiscount {
        try await simulateNetworkDelay()
        return discount // 模擬添加成功
    }
    
    func updateDiscount(_ discount: PriceDiscount) async throws -> PriceDiscount {
        try await simulateNetworkDelay()
        return discount // 模擬更新成功
    }
    
    func deleteDiscount(_ discount: PriceDiscount) async throws {
        try await simulateNetworkDelay()
        // 模擬刪除成功
    }
}
