import Foundation

// MARK: - Plaid service (scaffold)
//
// Real Plaid integration requires the Swift LinkKit SDK + a backend
// exchange endpoint for the Link → access-token swap. Keys and
// environment (sandbox/development/production) must never ship in the
// app bundle.
//
// This file is the protocol + a MockPlaidService so the rest of the app
// can be built and Plaid can be dropped in later without churning call
// sites.

public struct PlaidLinkToken: Sendable, Equatable {
    public let token: String
    public let expiration: Date
}

public struct PlaidAccount: Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let mask: String?
    public let institutionName: String
    public let balance: Double
}

public struct PlaidTransaction: Sendable, Identifiable, Equatable {
    public let id: String
    public let merchantName: String
    public let amount: Double        // positive = spend
    public let date: Date
    public let category: String
    public let isPending: Bool
}

public enum PlaidError: Error, Sendable {
    case notConfigured
    case linkCancelled
    case tokenExchangeFailed
    case network(String)
}

public protocol PlaidServiceProvider: Sendable {
    /// Ask the Splurj backend for a short-lived Link token keyed to the
    /// current user. Throws PlaidError.notConfigured until BACKEND_BASE
    /// + API keys are set.
    func requestLinkToken(for userID: String) async throws -> PlaidLinkToken

    /// Exchange the public_token Link returns for an access_token. The
    /// access_token NEVER leaves the backend — this returns only a
    /// Splurj-side bank connection id.
    func exchangePublicToken(_ publicToken: String) async throws -> String

    /// Pull accounts for a connected bank.
    func accounts(for connectionID: String) async throws -> [PlaidAccount]

    /// Pull recent transactions (max 90 days). `since` nil = last 30d.
    func transactions(for connectionID: String, since: Date?) async throws -> [PlaidTransaction]
}

public enum Plaid {
    /// Swap this to a real PlaidLiveService(baseURL:...) when the
    /// backend endpoints are live. Until then the mock returns
    /// deterministic data for UI development.
    public static var shared: PlaidServiceProvider = MockPlaidService()
}

// MARK: - Mock implementation (for UI development)

final class MockPlaidService: PlaidServiceProvider {
    func requestLinkToken(for userID: String) async throws -> PlaidLinkToken {
        try await Task.sleep(nanoseconds: 400_000_000)
        return PlaidLinkToken(
            token: "link-sandbox-\(userID.prefix(6))",
            expiration: Date().addingTimeInterval(3600)
        )
    }

    func exchangePublicToken(_ publicToken: String) async throws -> String {
        try await Task.sleep(nanoseconds: 600_000_000)
        return "conn_" + UUID().uuidString.prefix(8)
    }

    func accounts(for connectionID: String) async throws -> [PlaidAccount] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return [
            .init(id: "acct-checking", name: "Core Checking", mask: "0121", institutionName: "Chase", balance: 2_431.80),
            .init(id: "acct-savings", name: "Future Fund", mask: "9988", institutionName: "Chase", balance: 12_500.42),
        ]
    }

    func transactions(for connectionID: String, since: Date?) async throws -> [PlaidTransaction] {
        try await Task.sleep(nanoseconds: 500_000_000)
        let now = Date()
        func daysAgo(_ n: Int) -> Date { now.addingTimeInterval(-Double(n) * 86_400) }
        return [
            .init(id: "tx1", merchantName: "Starbucks",    amount: 5.25,  date: daysAgo(0), category: "Food & Drink", isPending: false),
            .init(id: "tx2", merchantName: "DoorDash",     amount: 32.10, date: daysAgo(1), category: "Food & Drink", isPending: false),
            .init(id: "tx3", merchantName: "Whole Foods",  amount: 76.44, date: daysAgo(2), category: "Groceries",    isPending: false),
            .init(id: "tx4", merchantName: "Spotify",      amount: 9.99,  date: daysAgo(3), category: "Subscriptions", isPending: false),
            .init(id: "tx5", merchantName: "REI",          amount: 132.0, date: daysAgo(4), category: "Shopping",     isPending: true),
        ]
    }
}
