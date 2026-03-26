import SwiftUI
import PDFKit

@MainActor
struct ExportService {

    static func exportCSV(transactions: [Transaction]) -> URL? {
        var csv = "Date,Type,Category,Amount,Note,Mood\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        for tx in transactions {
            let date = formatter.string(from: tx.date)
            let type = tx.transactionType.rawValue
            let category = tx.transactionCategory.rawValue
            let amount = String(format: "%.2f", tx.amount)
            let note = tx.note.replacingOccurrences(of: ",", with: ";")
            let mood = tx.moodEmoji
            csv += "\(date),\(type),\(category),\(amount),\(note),\(mood)\n"
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Splurj_Transactions.csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    static func exportPDF(transactions: [Transaction], profile: UserProfile?) -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let cal = Calendar.current
        let monthAgo = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let monthTx = transactions.filter { $0.date >= monthAgo }
        let expenses = monthTx.filter { $0.transactionType == .expense }
        let income = monthTx.filter { $0.transactionType == .income }
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        let totalIncome = income.reduce(0) { $0 + $1.amount }

        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let headerFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let smallFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let textColor = UIColor.white
        let secondaryColor = UIColor.gray
        let bgColor = UIColor(red: 10/255, green: 15/255, blue: 30/255, alpha: 1)

        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            let bg = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            bgColor.setFill()
            UIRectFill(bg)

            var y: CGFloat = margin

            let title = "Splurj Monthly Report"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: titleFont, .foregroundColor: textColor])
            y += 36

            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let subtitle = formatter.string(from: Date())
            subtitle.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: headerFont, .foregroundColor: secondaryColor])
            y += 40

            if let name = profile?.name {
                "Prepared for: \(name)".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: bodyFont, .foregroundColor: secondaryColor])
                y += 30
            }

            "Summary".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: headerFont, .foregroundColor: textColor])
            y += 24

            let summaryLines = [
                "Total Income: $\(String(format: "%.2f", totalIncome))",
                "Total Expenses: $\(String(format: "%.2f", totalExpense))",
                "Net: $\(String(format: "%.2f", totalIncome - totalExpense))",
                "Transactions: \(monthTx.count)"
            ]
            for line in summaryLines {
                line.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: [.font: bodyFont, .foregroundColor: textColor])
                y += 18
            }
            y += 20

            "Recent Transactions".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: headerFont, .foregroundColor: textColor])
            y += 24

            let headers = ["Date", "Category", "Amount", "Note"]
            let colWidths: [CGFloat] = [100, 100, 80, contentWidth - 280]
            var x = margin
            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: smallFont, .foregroundColor: secondaryColor])
                x += colWidths[i]
            }
            y += 16

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd"

            let displayTx = Array(monthTx.sorted { $0.date > $1.date }.prefix(40))
            for tx in displayTx {
                if y > pageHeight - margin - 20 {
                    context.beginPage()
                    bgColor.setFill()
                    UIRectFill(bg)
                    y = margin
                }
                x = margin
                let cols = [
                    dateFormatter.string(from: tx.date),
                    tx.transactionCategory.rawValue,
                    (tx.transactionType == .expense ? "-" : "+") + "$\(String(format: "%.2f", tx.amount))",
                    String(tx.note.prefix(30))
                ]
                for (i, col) in cols.enumerated() {
                    let rect = CGRect(x: x, y: y, width: colWidths[i] - 4, height: 14)
                    col.draw(in: rect, withAttributes: [.font: smallFont, .foregroundColor: textColor])
                    x += colWidths[i]
                }
                y += 16
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Splurj_Report.pdf")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}
