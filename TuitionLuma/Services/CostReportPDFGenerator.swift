import Foundation
import UIKit

struct CostReportPayload {
    var school: School
    var aidInput: AidInput
    var planningMode: PlanningMode
    var livingScenario: LivingScenario
    var residencyScenario: ResidencyScenario
    var degreePathScenario: DegreePathScenario
    var repaymentTerm: RepaymentTerm
    var annualCost: Double
    var totalDegreeCost: Double
    var netAnnualCost: Double
    var netTotalCost: Double
    var loanPrincipal: Double
    var monthlyPayment: Double
    var totalRepayment: Double
    var annualAidTotal: Double
    var totalFamilyContribution: Double
    var annualFamilyFundingGap: Double
    var annualStudentOutOfPocketGap: Double
}

enum CostReportPDFGenerator {
    static func generate(payload: CostReportPayload) throws -> URL {
        let fileName = "\(sanitizedFileName(payload.school.name))-TuitionLuma-Cost-Report.pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        try renderer.writePDF(to: outputURL) { context in
            context.beginPage()
            drawFirstPage(payload: payload, pageRect: pageRect)
            context.beginPage()
            drawSecondPage(payload: payload, pageRect: pageRect)
        }

        return outputURL
    }

    private static func drawFirstPage(payload: CostReportPayload, pageRect: CGRect) {
        drawHero(payload: payload, pageRect: pageRect)
        drawSummaryCards(payload: payload, startY: 196, pageRect: pageRect)
        drawCostBreakdown(payload: payload, startY: 348, pageRect: pageRect)
        drawAidAndScenario(payload: payload, startY: 590, pageRect: pageRect)
        drawFooter(pageRect: pageRect, pageNumber: 1)
    }

    private static func drawSecondPage(payload: CostReportPayload, pageRect: CGRect) {
        drawPageTitle("Repayment and family planning", subtitle: payload.school.name, pageRect: pageRect)
        drawRepaymentSection(payload: payload, startY: 102, pageRect: pageRect)
        drawFamilyPlanningSection(payload: payload, startY: 436, pageRect: pageRect)
        drawDataNotes(payload: payload, startY: 668, pageRect: pageRect)
        drawFooter(pageRect: pageRect, pageNumber: 2)
    }

    private static func drawHero(payload: CostReportPayload, pageRect: CGRect) {
        let heroRect = CGRect(x: 36, y: 34, width: pageRect.width - 72, height: 132)
        let path = UIBezierPath(roundedRect: heroRect, cornerRadius: 18)
        path.addClip()

        let context = UIGraphicsGetCurrentContext()
        let colors = [
            UIColor(red: 1.00, green: 0.35, blue: 0.36, alpha: 1).cgColor,
            UIColor(red: 1.00, green: 0.78, blue: 0.25, alpha: 1).cgColor,
            UIColor(red: 0.16, green: 0.75, blue: 0.78, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.48, 1])!
        context?.drawLinearGradient(gradient, start: heroRect.origin, end: CGPoint(x: heroRect.maxX, y: heroRect.maxY), options: [])

        UIColor.white.withAlphaComponent(0.18).setFill()
        UIBezierPath(ovalIn: CGRect(x: heroRect.maxX - 184, y: heroRect.minY - 78, width: 240, height: 240)).fill()

        drawText(
            "TuitionLuma Family Cost Report",
            in: CGRect(x: heroRect.minX + 24, y: heroRect.minY + 24, width: heroRect.width - 48, height: 24),
            font: .systemFont(ofSize: 15, weight: .bold),
            color: .white.withAlphaComponent(0.88)
        )
        drawText(
            payload.school.name,
            in: CGRect(x: heroRect.minX + 24, y: heroRect.minY + 50, width: heroRect.width - 180, height: 52),
            font: .systemFont(ofSize: 27, weight: .heavy),
            color: .white
        )
        drawText(
            "\(payload.school.city), \(payload.school.state) • \(payload.school.type.rawValue)",
            in: CGRect(x: heroRect.minX + 24, y: heroRect.minY + 104, width: heroRect.width - 48, height: 20),
            font: .systemFont(ofSize: 12, weight: .semibold),
            color: .white.withAlphaComponent(0.92)
        )
        drawBadge(
            "\(payload.school.valueLabel) • \(payload.school.lumaScore)/100",
            in: CGRect(x: heroRect.maxX - 162, y: heroRect.minY + 30, width: 126, height: 30),
            fill: .white.withAlphaComponent(0.22),
            text: .white
        )

        UIGraphicsGetCurrentContext()?.resetClip()
    }

    private static func drawSummaryCards(payload: CostReportPayload, startY: CGFloat, pageRect: CGRect) {
        let cards = [
            ("Net annual cost", currency(payload.netAnnualCost), UIColor(red: 0.10, green: 0.66, blue: 0.38, alpha: 1)),
            ("\(payload.aidInput.yearsInSchool)-year modeled total", currency(payload.netTotalCost), UIColor(red: 0.16, green: 0.75, blue: 0.78, alpha: 1)),
            ("Monthly loan payment", currency(payload.monthlyPayment), UIColor(red: 1.00, green: 0.35, blue: 0.36, alpha: 1))
        ]
        let cardWidth = (pageRect.width - 96) / 3

        for index in cards.indices {
            let card = cards[index]
            let rect = CGRect(x: 36 + CGFloat(index) * (cardWidth + 12), y: startY, width: cardWidth, height: 98)
            drawCard(rect)
            drawText(card.1, in: CGRect(x: rect.minX + 14, y: rect.minY + 18, width: rect.width - 28, height: 28), font: .systemFont(ofSize: 22, weight: .heavy), color: card.2)
            drawText(card.0, in: CGRect(x: rect.minX + 14, y: rect.minY + 52, width: rect.width - 28, height: 18), font: .systemFont(ofSize: 11, weight: .bold), color: ink.withAlphaComponent(0.78))
            drawText("After entered aid and scenario choices.", in: CGRect(x: rect.minX + 14, y: rect.minY + 71, width: rect.width - 28, height: 16), font: .systemFont(ofSize: 9, weight: .medium), color: slate)
        }
    }

    private static func drawCostBreakdown(payload: CostReportPayload, startY: CGFloat, pageRect: CGRect) {
        drawSectionTitle("Annual cost breakdown", subtitle: "Sticker price components before grants, scholarships, or family contributions.", x: 36, y: startY)

        let cost = payload.school.costEstimate
        let rows = [
            ("Tuition", cost.tuitionAndFees, UIColor(red: 0.10, green: 0.66, blue: 0.38, alpha: 1)),
            ("Housing and meals", cost.housingAndMeals, UIColor(red: 1.00, green: 0.78, blue: 0.25, alpha: 1)),
            ("Books and supplies", cost.booksAndSupplies, UIColor(red: 0.16, green: 0.75, blue: 0.78, alpha: 1)),
            ("Transportation", cost.transportation, UIColor(red: 0.35, green: 0.84, blue: 0.52, alpha: 1)),
            ("Personal expenses", cost.personalExpenses, UIColor(red: 0.32, green: 0.36, blue: 0.46, alpha: 1))
        ].filter { $0.1 > 0 }

        let chartRect = CGRect(x: 36, y: startY + 58, width: pageRect.width - 72, height: 154)
        drawCard(chartRect)

        let maxValue = max(rows.map(\.1).max() ?? 1, 1)
        for (index, row) in rows.enumerated() {
            let y = chartRect.minY + 18 + CGFloat(index) * 25
            drawText(row.0, in: CGRect(x: chartRect.minX + 18, y: y, width: 122, height: 16), font: .systemFont(ofSize: 10, weight: .semibold), color: slate)

            let barX = chartRect.minX + 152
            let barWidth = chartRect.width - 250
            drawRoundedRect(CGRect(x: barX, y: y + 3, width: barWidth, height: 10), color: UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1), radius: 5)
            drawRoundedRect(CGRect(x: barX, y: y + 3, width: max(8, barWidth * row.1 / maxValue), height: 10), color: row.2, radius: 5)

            drawText(currency(row.1), in: CGRect(x: chartRect.maxX - 76, y: y - 1, width: 58, height: 16), font: .systemFont(ofSize: 10, weight: .bold), color: ink, alignment: .right)
        }
    }

    private static func drawAidAndScenario(payload: CostReportPayload, startY: CGFloat, pageRect: CGRect) {
        let left = CGRect(x: 36, y: startY, width: 258, height: 122)
        let right = CGRect(x: 318, y: startY, width: 258, height: 122)
        drawCard(left)
        drawCard(right)

        drawText("Aid plan", in: CGRect(x: left.minX + 16, y: left.minY + 14, width: left.width - 32, height: 20), font: .systemFont(ofSize: 15, weight: .bold), color: ink)
        drawMiniRow("Grants/scholarships", currency(payload.aidInput.grantsAndScholarships), x: left.minX + 16, y: left.minY + 46, width: left.width - 32)
        drawMiniRow("Family contribution", currency(payload.aidInput.familyContribution), x: left.minX + 16, y: left.minY + 68, width: left.width - 32)
        drawMiniRow("Work-study", currency(payload.aidInput.workStudy), x: left.minX + 16, y: left.minY + 90, width: left.width - 32)

        drawText("Scenario", in: CGRect(x: right.minX + 16, y: right.minY + 14, width: right.width - 32, height: 20), font: .systemFont(ofSize: 15, weight: .bold), color: ink)
        drawMiniRow("Planning mode", payload.planningMode.rawValue, x: right.minX + 16, y: right.minY + 46, width: right.width - 32)
        drawMiniRow("Living", payload.livingScenario.rawValue, x: right.minX + 16, y: right.minY + 68, width: right.width - 32)
        drawMiniRow("Path", payload.degreePathScenario.title, x: right.minX + 16, y: right.minY + 90, width: right.width - 32)
    }

    private static func drawRepaymentSection(payload: CostReportPayload, startY: CGFloat, pageRect: CGRect) {
        drawSectionTitle("Debt repayment view", subtitle: "A planning estimate based on entered annual borrowing and interest rate.", x: 36, y: startY)

        let card = CGRect(x: 36, y: startY + 58, width: pageRect.width - 72, height: 160)
        drawCard(card)

        let metrics = [
            ("Borrowed", currency(payload.loanPrincipal)),
            ("Monthly payment", currency(payload.monthlyPayment)),
            ("Total repayment", currency(payload.totalRepayment)),
            ("Loan term", "\(payload.repaymentTerm.rawValue) years")
        ]

        for index in metrics.indices {
            let column = index % 2
            let row = index / 2
            let rect = CGRect(x: card.minX + 18 + CGFloat(column) * 252, y: card.minY + 20 + CGFloat(row) * 62, width: 222, height: 50)
            drawText(metrics[index].1, in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 26), font: .systemFont(ofSize: 22, weight: .heavy), color: index == 1 ? aqua : ink)
            drawText(metrics[index].0, in: CGRect(x: rect.minX, y: rect.minY + 30, width: rect.width, height: 16), font: .systemFont(ofSize: 10, weight: .bold), color: slate)
        }

        drawProgressComparison(
            title: "Repayment compared with net total",
            firstLabel: "Modeled net total",
            firstValue: payload.netTotalCost,
            secondLabel: "Total repayment",
            secondValue: payload.totalRepayment,
            x: 36,
            y: startY + 246,
            width: pageRect.width - 72
        )
    }

    private static func drawFamilyPlanningSection(payload: CostReportPayload, startY: CGFloat, pageRect: CGRect) {
        drawSectionTitle("Family planning snapshot", subtitle: "How the selected plan splits annual cost, aid, borrowing, and remaining gap.", x: 36, y: startY)

        let card = CGRect(x: 36, y: startY + 58, width: pageRect.width - 72, height: 164)
        drawCard(card)

        let total = max(payload.annualCost, 1)
        let segments = [
            ("Aid", payload.annualAidTotal, mint),
            ("Family", payload.aidInput.familyContribution, UIColor(red: 1.00, green: 0.78, blue: 0.25, alpha: 1)),
            ("Loans", payload.aidInput.annualLoanAmount, coral),
            ("Gap", payload.annualFamilyFundingGap, UIColor(red: 0.95, green: 0.38, blue: 0.16, alpha: 1))
        ].filter { $0.1 > 0 }

        var x = card.minX + 18
        let barY = card.minY + 42
        let barWidth = card.width - 36
        for segment in segments {
            let width = max(8, barWidth * segment.1 / total)
            drawRoundedRect(CGRect(x: x, y: barY, width: width, height: 18), color: segment.2, radius: 9)
            x += width
        }

        drawMiniRow("Modeled annual cost", currency(payload.annualCost), x: card.minX + 18, y: card.minY + 82, width: card.width - 36)
        drawMiniRow("Aid and work-study", currency(payload.annualAidTotal), x: card.minX + 18, y: card.minY + 106, width: card.width - 36)
        drawMiniRow("Family contribution", currency(payload.aidInput.familyContribution), x: card.minX + 18, y: card.minY + 130, width: card.width - 36)
        drawMiniRow("Student cash gap after loans", currency(payload.annualStudentOutOfPocketGap), x: card.minX + 18, y: card.minY + 146, width: card.width - 36)
    }

    private static func drawDataNotes(payload: CostReportPayload, startY: CGFloat, pageRect: CGRect) {
        let rect = CGRect(x: 36, y: startY, width: pageRect.width - 72, height: 62)
        drawRoundedRect(rect, color: UIColor(red: 0.91, green: 0.98, blue: 0.95, alpha: 1), radius: 16)

        drawText("Data notes", in: CGRect(x: rect.minX + 18, y: rect.minY + 12, width: rect.width - 36, height: 18), font: .systemFont(ofSize: 13, weight: .bold), color: ink)

        var note = "College data comes from the U.S. Department of Education College Scorecard when available. TuitionLuma estimates marked or implied in the app use planning assumptions for missing cost line items."
        if !payload.school.missingDataFields.isEmpty {
            note += " Missing federal fields: \(payload.school.missingDataFields.prefix(5).joined(separator: ", "))."
        }

        drawText(note, in: CGRect(x: rect.minX + 18, y: rect.minY + 32, width: rect.width - 36, height: 24), font: .systemFont(ofSize: 8.5, weight: .medium), color: slate)
    }

    private static func drawProgressComparison(title: String, firstLabel: String, firstValue: Double, secondLabel: String, secondValue: Double, x: CGFloat, y: CGFloat, width: CGFloat) {
        drawText(title, in: CGRect(x: x, y: y, width: width, height: 18), font: .systemFont(ofSize: 12, weight: .bold), color: ink)

        let maxValue = max(firstValue, secondValue, 1)
        drawComparisonBar(label: firstLabel, value: firstValue, maxValue: maxValue, color: mint, x: x, y: y + 30, width: width)
        drawComparisonBar(label: secondLabel, value: secondValue, maxValue: maxValue, color: coral, x: x, y: y + 62, width: width)
    }

    private static func drawComparisonBar(label: String, value: Double, maxValue: Double, color: UIColor, x: CGFloat, y: CGFloat, width: CGFloat) {
        drawText(label, in: CGRect(x: x, y: y - 2, width: 116, height: 16), font: .systemFont(ofSize: 10, weight: .semibold), color: slate)
        drawRoundedRect(CGRect(x: x + 128, y: y, width: width - 228, height: 12), color: UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1), radius: 6)
        drawRoundedRect(CGRect(x: x + 128, y: y, width: max(8, (width - 228) * value / maxValue), height: 12), color: color, radius: 6)
        drawText(currency(value), in: CGRect(x: x + width - 86, y: y - 3, width: 86, height: 18), font: .systemFont(ofSize: 10, weight: .bold), color: ink, alignment: .right)
    }

    private static func drawPageTitle(_ title: String, subtitle: String, pageRect: CGRect) {
        drawText(title, in: CGRect(x: 36, y: 38, width: pageRect.width - 72, height: 28), font: .systemFont(ofSize: 23, weight: .heavy), color: ink)
        drawText(subtitle, in: CGRect(x: 36, y: 68, width: pageRect.width - 72, height: 18), font: .systemFont(ofSize: 11, weight: .semibold), color: slate)
    }

    private static func drawSectionTitle(_ title: String, subtitle: String, x: CGFloat, y: CGFloat) {
        drawText(title, in: CGRect(x: x, y: y, width: 420, height: 22), font: .systemFont(ofSize: 17, weight: .bold), color: ink)
        drawText(subtitle, in: CGRect(x: x, y: y + 25, width: 500, height: 18), font: .systemFont(ofSize: 10.5, weight: .medium), color: slate)
    }

    private static func drawMiniRow(_ title: String, _ value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        drawText(title, in: CGRect(x: x, y: y, width: width * 0.62, height: 17), font: .systemFont(ofSize: 10.5, weight: .semibold), color: slate)
        drawText(value, in: CGRect(x: x + width * 0.45, y: y, width: width * 0.55, height: 17), font: .systemFont(ofSize: 10.5, weight: .bold), color: ink, alignment: .right)
    }

    private static func drawBadge(_ text: String, in rect: CGRect, fill: UIColor, text textColor: UIColor) {
        drawRoundedRect(rect, color: fill, radius: rect.height / 2)
        drawText(text, in: rect.insetBy(dx: 10, dy: 6), font: .systemFont(ofSize: 9.5, weight: .heavy), color: textColor, alignment: .center)
    }

    private static func drawCard(_ rect: CGRect) {
        drawRoundedRect(rect, color: .white, radius: 16)
        UIColor.black.withAlphaComponent(0.06).setStroke()
        UIBezierPath(roundedRect: rect, cornerRadius: 16).stroke()
    }

    private static func drawRoundedRect(_ rect: CGRect, color: UIColor, radius: CGFloat) {
        color.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
    }

    private static func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]

        (text as NSString).draw(in: rect, withAttributes: attributes)
    }

    private static func drawFooter(pageRect: CGRect, pageNumber: Int) {
        drawText("Generated by TuitionLuma", in: CGRect(x: 36, y: pageRect.maxY - 38, width: 220, height: 16), font: .systemFont(ofSize: 9.5, weight: .semibold), color: slate)
        drawText("Page \(pageNumber)", in: CGRect(x: pageRect.maxX - 96, y: pageRect.maxY - 38, width: 60, height: 16), font: .systemFont(ofSize: 9.5, weight: .semibold), color: slate, alignment: .right)
    }

    private static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private static func sanitizedFileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return name
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowed.contains($0) ? String($0) : "" }
            .joined()
            .prefix(60)
            .description
    }

    private static let ink = UIColor(red: 0.09, green: 0.10, blue: 0.18, alpha: 1)
    private static let slate = UIColor(red: 0.32, green: 0.36, blue: 0.46, alpha: 1)
    private static let coral = UIColor(red: 1.00, green: 0.35, blue: 0.36, alpha: 1)
    private static let aqua = UIColor(red: 0.16, green: 0.75, blue: 0.78, alpha: 1)
    private static let mint = UIColor(red: 0.35, green: 0.84, blue: 0.52, alpha: 1)
}
