//
//  Formatters.swift
//  L-ark
//
//  Created by Jose Rodriguez on 12-09-25.
//

import Foundation
class Formatters {
    static func formatDate(_ date: Date) -> String {
            let calendar = Calendar.current
            let now = Date()
            
            if calendar.isDateInToday(date) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Hoy a las \(formatter.string(from: date))"
            } else if calendar.isDateInYesterday(date) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Ayer a las \(formatter.string(from: date))"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
        }
        
        static func formatAmount(_ amount: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = "."
            formatter.decimalSeparator = ","
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            
            if let formattedAmount = formatter.string(from: amount as NSNumber) {
                return "$\(formattedAmount)"
            }
            
            return "$\(amount)"
        }
}
