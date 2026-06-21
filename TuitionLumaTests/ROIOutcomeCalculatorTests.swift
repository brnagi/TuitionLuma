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

    func testROIScoreVariesAcrossDifferentSchoolOutcomes() {
        let strongerSchool = makeSchool(
            medianEarnings: 76_000,
            averageDebt: 18_000,
            netPrice: 12_000,
            graduationRate: 0.82,
            lumaScore: 88
        )
        let weakerSchool = makeSchool(
            medianEarnings: 42_000,
            averageDebt: 33_000,
            netPrice: 24_000,
            graduationRate: 0.48,
            lumaScore: 58
        )

        let strongerResult = ROIOutcomeCalculator.result(for: strongerSchool)
        let weakerResult = ROIOutcomeCalculator.result(for: weakerSchool)

        XCTAssertGreaterThan(strongerResult.score, weakerResult.score)
        XCTAssertNotEqual(strongerResult.score, weakerResult.score)
    }

    func testHighDebtProgramScoresLowerThanLowerDebtProgram() {
        let school = makeSchool(medianEarnings: 62_000, averageDebt: 22_000)
        let lowerDebtProgram = AcademicProgram(
            name: "Information Technology",
            credential: "Bachelor's Degree",
            cipCode: "11.10",
            medianEarnings: 72_000,
            debt: 16_000,
            typicalDurationYears: 4
        )
        let higherDebtProgram = AcademicProgram(
            name: "Information Technology",
            credential: "Bachelor's Degree",
            cipCode: "11.10",
            medianEarnings: 72_000,
            debt: 46_000,
            typicalDurationYears: 4
        )

        let lowerDebtResult = ROIOutcomeCalculator.result(for: school, program: lowerDebtProgram, estimatedNetCost: 16_000)
        let higherDebtResult = ROIOutcomeCalculator.result(for: school, program: higherDebtProgram, estimatedNetCost: 16_000)

        XCTAssertGreaterThan(lowerDebtResult.score, higherDebtResult.score)
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

    func testProfileRankingsChangeWithIntendedMajor() {
        let nursingStrongSchool = makeSchool(
            name: "Nursing State University",
            medianEarnings: 55_000,
            averageDebt: 24_000,
            programs: [
                AcademicProgram(
                    name: "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing",
                    credential: "Bachelor's Degree",
                    cipCode: "51.38",
                    medianEarnings: 86_000,
                    debt: 17_000,
                    completionCount: 420,
                    typicalDurationYears: 4
                ),
                AcademicProgram(
                    name: "Computer and Information Sciences",
                    credential: "Bachelor's Degree",
                    cipCode: "11.01",
                    medianEarnings: 58_000,
                    debt: 31_000,
                    completionCount: 120,
                    typicalDurationYears: 4
                )
            ]
        )
        let computerScienceStrongSchool = makeSchool(
            name: "Technology State University",
            medianEarnings: 55_000,
            averageDebt: 24_000,
            programs: [
                AcademicProgram(
                    name: "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing",
                    credential: "Bachelor's Degree",
                    cipCode: "51.38",
                    medianEarnings: 58_000,
                    debt: 31_000,
                    completionCount: 125,
                    typicalDurationYears: 4
                ),
                AcademicProgram(
                    name: "Computer and Information Sciences",
                    credential: "Bachelor's Degree",
                    cipCode: "11.01",
                    medianEarnings: 96_000,
                    debt: 18_000,
                    completionCount: 460,
                    typicalDurationYears: 4
                )
            ]
        )
        let schools = [computerScienceStrongSchool, nursingStrongSchool]
        let nursingProfile = makeProfile(intendedMajor: "Nursing")
        let computerScienceProfile = makeProfile(intendedMajor: "Computer Science")

        let nursingRanking = StudentProfileRecommendationEngine.rankedSchools(schools, profile: nursingProfile)
        let computerScienceRanking = StudentProfileRecommendationEngine.rankedSchools(schools, profile: computerScienceProfile)

        XCTAssertEqual(nursingRanking.first?.name, "Nursing State University")
        XCTAssertEqual(computerScienceRanking.first?.name, "Technology State University")
    }

    func testRecommendationGradeMatchesPersonalizedROIOutcome() {
        let school = makeSchool(
            medianEarnings: 55_000,
            averageDebt: 24_000,
            programs: [
                AcademicProgram(
                    name: "Computer and Information Sciences",
                    credential: "Bachelor's Degree",
                    cipCode: "11.01",
                    medianEarnings: 78_000,
                    debt: 22_000,
                    completionCount: 230,
                    typicalDurationYears: 4
                )
            ]
        )
        let profile = makeProfile(intendedMajor: "Computer Science")

        let recommendation = StudentProfileRecommendationEngine.recommendation(for: school, profile: profile)
        let roiOutcome = StudentProfileRecommendationEngine.personalizedROIOutcome(for: school, profile: profile)

        XCTAssertEqual(recommendation.roiGrade, roiOutcome.grade)
    }

    func testProfileMajorMatchesLoadedProgramCatalog() {
        let school = makeSchool(
            medianEarnings: 58_000,
            averageDebt: 18_000,
            programs: []
        )
        let programs = [
            AcademicProgram(
                name: "Marketing",
                credential: "Bachelor's Degree",
                cipCode: "52.14",
                medianEarnings: 55_000,
                debt: 19_000,
                typicalDurationYears: 4,
                category: "Business"
            ),
            AcademicProgram(
                name: "Computer and Information Sciences",
                credential: "Bachelor's Degree",
                cipCode: "11.01",
                medianEarnings: 92_000,
                debt: 21_000,
                typicalDurationYears: 4,
                category: "Computer and information sciences"
            )
        ]
        let profile = makeProfile(intendedMajor: "Computer Science")

        let match = StudentProfileRecommendationEngine.matchingProgram(
            in: programs,
            for: school,
            profile: profile
        )

        XCTAssertEqual(match?.name, "Computer and Information Sciences")
    }

    func testProfileWithoutIntendedMajorStillRanksByResidency() {
        let homeStateSchool = makeSchool(
            name: "Texas Value University",
            state: "TX",
            medianEarnings: 62_000,
            averageDebt: 18_000
        )
        let outOfStateSchool = makeSchool(
            name: "Out of State University",
            state: "CA",
            medianEarnings: 62_000,
            averageDebt: 18_000
        )
        let profile = makeProfile(intendedMajor: "")

        let rankedSchools = StudentProfileRecommendationEngine.rankedSchools(
            [outOfStateSchool, homeStateSchool],
            profile: profile
        )

        XCTAssertTrue(profile.isComplete)
        XCTAssertEqual(rankedSchools.first?.name, "Texas Value University")
    }

    func testBusinessMajorMatchesBusinessProgramBeforeHigherROINursingProgram() {
        let school = makeSchool(
            medianEarnings: 58_000,
            averageDebt: 18_000,
            programs: []
        )
        let programs = [
            AcademicProgram(
                name: "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing",
                credential: "Master's Degree",
                cipCode: "51.38",
                medianEarnings: 126_000,
                debt: 21_000,
                typicalDurationYears: 4,
                category: "Health"
            ),
            AcademicProgram(
                name: "Business Administration, Management and Operations",
                credential: "Bachelor's Degree",
                cipCode: "52.02",
                medianEarnings: 64_000,
                debt: 17_000,
                typicalDurationYears: 4,
                category: "Business"
            )
        ]
        let profile = makeProfile(intendedMajor: "Business Administration")

        let match = StudentProfileRecommendationEngine.matchingProgram(
            in: programs,
            for: school,
            profile: profile
        )

        XCTAssertEqual(match?.name, "Business Administration, Management and Operations")
    }

    func testBusinessMajorReturnsNoProgramWhenCatalogHasOnlyUnrelatedPrograms() {
        let school = makeSchool(
            medianEarnings: 58_000,
            averageDebt: 18_000,
            programs: []
        )
        let programs = [
            AcademicProgram(
                name: "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing",
                credential: "Master's Degree",
                cipCode: "51.38",
                medianEarnings: 126_000,
                debt: 21_000,
                typicalDurationYears: 4,
                category: "Health"
            )
        ]
        let profile = makeProfile(intendedMajor: "Business Administration")

        let match = StudentProfileRecommendationEngine.matchingProgram(
            in: programs,
            for: school,
            profile: profile
        )

        XCTAssertNil(match)
    }

    @MainActor
    func testRememberRefreshesSavedSchoolProgramCatalog() {
        let suiteName = "TuitionLumaTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let viewModel = AppViewModel(userDefaults: userDefaults)
        let school = makeSchool(name: "Catalog University", medianEarnings: 58_000, averageDebt: 18_000)
        _ = viewModel.toggleSaved(school)

        var updatedSchool = school
        updatedSchool.programs = [
            AcademicProgram(
                name: "Computer and Information Sciences",
                credential: "Bachelor's Degree",
                cipCode: "11.01",
                medianEarnings: 92_000,
                debt: 21_000,
                typicalDurationYears: 4
            )
        ]

        viewModel.remember([updatedSchool])

        XCTAssertEqual(viewModel.savedSchools.first?.programs.first?.name, "Computer and Information Sciences")
    }

    @MainActor
    func testFreeSaveLimitIgnoresUnrestoredStaleSavedIDs() {
        let suiteName = "TuitionLumaTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.set(["stale-1", "stale-2", "stale-3"], forKey: "tuitionLuma.savedSchoolIDs")
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let viewModel = AppViewModel(userDefaults: userDefaults)
        let result = viewModel.toggleSaved(
            makeSchool(name: "Visible Test University", medianEarnings: 62_000, averageDebt: 18_000),
            savedLimit: 3
        )

        switch result {
        case .saved:
            break
        default:
            XCTFail("Expected the first visible saved school to be allowed.")
        }
    }

    private func makeSchool(
        name: String = "Test University",
        state: String = "TX",
        medianEarnings: Double,
        averageDebt: Double,
        netPrice: Double = 13_500,
        graduationRate: Double = 0.68,
        lumaScore: Int = 74,
        programs: [AcademicProgram] = []
    ) -> School {
        School(
            scorecardID: 123,
            name: name,
            city: "Austin",
            state: state,
            type: .publicUniversity,
            acceptanceRate: 0.72,
            graduationRate: graduationRate,
            lumaScore: lumaScore,
            valueLabel: "Good Value",
            medianEarnings: medianEarnings,
            averageDebt: averageDebt,
            studentCount: 20_000,
            campusVibe: "Test campus",
            programs: programs,
            costEstimate: CostEstimate(
                tuitionAndFees: 11_000,
                outOfStateTuition: 28_000,
                costOfAttendance: 24_000,
                reportedAverageNetPrice: netPrice,
                housingAndMeals: 9_000,
                booksAndSupplies: 1_200,
                transportation: 1_000,
                personalExpenses: 1_500,
                averageGrantAid: 7_000
            ),
            highlights: ["Research"]
        )
    }

    private func makeProfile(intendedMajor: String) -> StudentProfile {
        StudentProfile(
            gpa: 3.4,
            testScore: "",
            stateResidency: "TX",
            intendedMajor: intendedMajor,
            familyIncomeRange: .range75to110k
        )
    }
}

@MainActor
final class CalculatorViewModelTests: XCTestCase {
    func testOutOfStateScenarioUsesReportedOutOfStateTuition() {
        let school = makeSchool(
            type: .publicUniversity,
            tuitionAndFees: 12_000,
            outOfStateTuition: 32_000,
            costOfAttendance: 25_000
        )
        let viewModel = CalculatorViewModel(school: school)

        XCTAssertEqual(viewModel.annualCost, 25_000)

        viewModel.residencyScenario = .outOfState

        XCTAssertEqual(viewModel.annualCost, 45_000)
    }

    func testOutOfStateScenarioEstimatesPublicSchoolTuitionWhenMissing() {
        let school = makeSchool(
            type: .publicUniversity,
            tuitionAndFees: 10_000,
            outOfStateTuition: nil,
            costOfAttendance: 22_000
        )
        let viewModel = CalculatorViewModel(school: school)

        viewModel.residencyScenario = .outOfState

        XCTAssertEqual(viewModel.annualCost, 35_500)
    }

    func testOutOfStateScenarioDoesNotIncreasePrivateSchoolTuitionWhenMissing() {
        let school = makeSchool(
            type: .privateNonprofit,
            tuitionAndFees: 30_000,
            outOfStateTuition: nil,
            costOfAttendance: 48_000
        )
        let viewModel = CalculatorViewModel(school: school)

        viewModel.residencyScenario = .outOfState

        XCTAssertEqual(viewModel.annualCost, 48_000)
    }

    private func makeSchool(
        type: School.SchoolType,
        tuitionAndFees: Double,
        outOfStateTuition: Double?,
        costOfAttendance: Double
    ) -> School {
        School(
            scorecardID: 987,
            name: "Scenario University",
            city: "Austin",
            state: "TX",
            type: type,
            acceptanceRate: 0.7,
            graduationRate: 0.68,
            lumaScore: 74,
            valueLabel: "Good Value",
            medianEarnings: 62_000,
            averageDebt: 19_000,
            studentCount: 22_000,
            campusVibe: "Test campus",
            programs: [],
            costEstimate: CostEstimate(
                tuitionAndFees: tuitionAndFees,
                outOfStateTuition: outOfStateTuition,
                costOfAttendance: costOfAttendance,
                reportedAverageNetPrice: 16_000,
                housingAndMeals: 9_000,
                booksAndSupplies: 1_200,
                transportation: 1_000,
                personalExpenses: 1_500,
                averageGrantAid: 6_000
            ),
            highlights: []
        )
    }
}
