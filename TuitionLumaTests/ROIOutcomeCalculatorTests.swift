import XCTest
@testable import TuitionLuma

final class ROIOutcomeCalculatorTests: XCTestCase {
    func testUsesInstitutionOutcomesWhenProgramIsMissing() {
        let school = makeSchool(medianEarnings: 62_000, averageDebt: 19_500)

        let result = ROIOutcomeCalculator.result(for: school, program: nil, estimatedNetCost: 14_000)

        XCTAssertEqual(result.earnings, 62_000)
        XCTAssertEqual(result.debt, 19_500)
        XCTAssertFalse(result.usedProgramEarnings)
        XCTAssertFalse(result.usedProgramDebt)
    }

    func testFallsBackToInstitutionValuesWhenProgramDataIsMissing() {
        let school = makeSchool(medianEarnings: 58_000, averageDebt: 21_000)
        let program = AcademicProgram(
            name: "Computer and Information Sciences",
            credential: "Bachelor's Degree",
            cipCode: "11.01",
            medianEarnings: 0,
            debt: nil,
            typicalDurationYears: 4
        )

        let result = ROIOutcomeCalculator.result(for: school, program: program, estimatedNetCost: 16_000)

        XCTAssertEqual(result.earnings, 58_000)
        XCTAssertEqual(result.debt, 21_000)
        XCTAssertFalse(result.usedProgramEarnings)
        XCTAssertFalse(result.usedProgramDebt)
    }

    func testUsesProgramValuesWhenReported() {
        let school = makeSchool(medianEarnings: 50_000, averageDebt: 22_000)
        let program = AcademicProgram(
            name: "Management Information Systems",
            credential: "Bachelor's Degree",
            cipCode: "52.12",
            medianEarnings: 78_000,
            debt: 17_250,
            typicalDurationYears: 4
        )

        let result = ROIOutcomeCalculator.result(for: school, program: program, estimatedNetCost: 15_000)

        XCTAssertEqual(result.earnings, 78_000)
        XCTAssertEqual(result.debt, 17_250)
        XCTAssertTrue(result.usedProgramEarnings)
        XCTAssertTrue(result.usedProgramDebt)
    }

    func testPoliticalScienceDoesNotAssumeGraduateSchool() {
        let labels = AcademicProgramPathClassifier.labels(
            name: "Political Science and Government",
            credential: "Bachelor's Degree",
            cipCode: "45.10"
        )

        XCTAssertTrue(labels.contains(.standardUndergraduate))
        XCTAssertFalse(labels.contains(.graduateSchoolLikely))
    }

    private func makeSchool(
        medianEarnings: Double,
        averageDebt: Double
    ) -> School {
        School(
            scorecardID: 123,
            name: "Test University",
            city: "Austin",
            state: "TX",
            type: .publicUniversity,
            acceptanceRate: 0.72,
            graduationRate: 0.68,
            lumaScore: 74,
            valueLabel: "Good Value",
            medianEarnings: medianEarnings,
            averageDebt: averageDebt,
            studentCount: 20_000,
            campusVibe: "Test campus",
            programs: [],
            costEstimate: CostEstimate(
                tuitionAndFees: 11_000,
                outOfStateTuition: 28_000,
                costOfAttendance: 24_000,
                reportedAverageNetPrice: 13_500,
                housingAndMeals: 9_000,
                booksAndSupplies: 1_200,
                transportation: 1_000,
                personalExpenses: 1_500,
                averageGrantAid: 7_000
            ),
            highlights: ["Research"]
        )
    }
}
