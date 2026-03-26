import SwiftUI
import SwiftData

struct CurrencyHelper {
    static func symbol(for code: String) -> String {
        let symbols: [String: String] = [
            "USD": "$", "EUR": "€", "GBP": "£", "THB": "฿", "JPY": "¥",
            "AUD": "A$", "CAD": "C$", "INR": "₹", "KRW": "₩", "CNY": "¥",
            "BRL": "R$", "MXN": "MX$", "CHF": "CHF", "SEK": "kr", "NOK": "kr",
            "DKK": "kr", "PLN": "zł", "CZK": "Kč", "HUF": "Ft", "RUB": "₽",
            "TRY": "₺", "ZAR": "R", "SGD": "S$", "HKD": "HK$", "NZD": "NZ$",
            "PHP": "₱", "IDR": "Rp", "MYR": "RM", "VND": "₫", "TWD": "NT$"
        ]
        return symbols[code] ?? code
    }
}
