import Foundation

enum MockSchools {
    static let all: [School] = [
        School(
            name: "University of Michigan",
            city: "Ann Arbor",
            state: "MI",
            type: .publicUniversity,
            acceptanceRate: 0.18,
            graduationRate: 0.93,
            medianEarnings: 78_500,
            averageDebt: 22_800,
            studentCount: 51_225,
            campusVibe: "Big research energy with strong alumni outcomes.",
            programs: [
                Program(name: "Computer Science", credential: "BS", medianEarnings: 103_000, typicalDurationYears: 4),
                Program(name: "Business Administration", credential: "BBA", medianEarnings: 86_000, typicalDurationYears: 4),
                Program(name: "Public Policy", credential: "BA", medianEarnings: 67_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 17_786, housingAndMeals: 14_460, booksAndSupplies: 1_124, transportation: 1_200, personalExpenses: 2_454, averageGrantAid: 19_100),
            highlights: ["Top public research university", "Strong earnings after graduation", "Large campus network"]
        ),
        School(
            name: "Arizona State University",
            city: "Tempe",
            state: "AZ",
            type: .publicUniversity,
            acceptanceRate: 0.90,
            graduationRate: 0.71,
            medianEarnings: 58_700,
            averageDebt: 20_400,
            studentCount: 79_593,
            campusVibe: "Flexible, sunny, and career-focused.",
            programs: [
                Program(name: "Engineering", credential: "BSE", medianEarnings: 82_000, typicalDurationYears: 4),
                Program(name: "Nursing", credential: "BSN", medianEarnings: 73_000, typicalDurationYears: 4),
                Program(name: "Digital Audiences", credential: "BA", medianEarnings: 54_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 12_698, housingAndMeals: 15_116, booksAndSupplies: 1_320, transportation: 1_386, personalExpenses: 2_200, averageGrantAid: 12_750),
            highlights: ["Large online and campus options", "Broad program selection", "Good transfer pathways"]
        ),
        School(
            name: "Spelman College",
            city: "Atlanta",
            state: "GA",
            type: .liberalArts,
            acceptanceRate: 0.28,
            graduationRate: 0.76,
            medianEarnings: 61_900,
            averageDebt: 25_300,
            studentCount: 2_417,
            campusVibe: "Close-knit liberal arts community with powerful mentorship.",
            programs: [
                Program(name: "Biology", credential: "BS", medianEarnings: 58_000, typicalDurationYears: 4),
                Program(name: "Psychology", credential: "BA", medianEarnings: 49_000, typicalDurationYears: 4),
                Program(name: "Economics", credential: "BA", medianEarnings: 68_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 30_058, housingAndMeals: 16_293, booksAndSupplies: 1_500, transportation: 1_450, personalExpenses: 2_000, averageGrantAid: 18_400),
            highlights: ["Historic women's college", "Strong graduate school pipeline", "Small classes"]
        ),
        School(
            name: "Purdue University",
            city: "West Lafayette",
            state: "IN",
            type: .publicUniversity,
            acceptanceRate: 0.53,
            graduationRate: 0.84,
            medianEarnings: 70_800,
            averageDebt: 19_700,
            studentCount: 52_211,
            campusVibe: "STEM-heavy, practical, and value-minded.",
            programs: [
                Program(name: "Aerospace Engineering", credential: "BS", medianEarnings: 89_000, typicalDurationYears: 4),
                Program(name: "Data Science", credential: "BS", medianEarnings: 94_000, typicalDurationYears: 4),
                Program(name: "Supply Chain", credential: "BS", medianEarnings: 74_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 9_992, housingAndMeals: 10_030, booksAndSupplies: 1_010, transportation: 1_250, personalExpenses: 1_830, averageGrantAid: 9_600),
            highlights: ["Tuition freeze value", "Excellent engineering reputation", "High ROI programs"]
        ),
        School(
            name: "Howard University",
            city: "Washington",
            state: "DC",
            type: .privateNonprofit,
            acceptanceRate: 0.35,
            graduationRate: 0.65,
            medianEarnings: 64_300,
            averageDebt: 27_600,
            studentCount: 12_886,
            campusVibe: "Mission-driven campus in the center of policy and culture.",
            programs: [
                Program(name: "Political Science", credential: "BA", medianEarnings: 58_000, typicalDurationYears: 4),
                Program(name: "Finance", credential: "BBA", medianEarnings: 77_000, typicalDurationYears: 4),
                Program(name: "Journalism", credential: "BA", medianEarnings: 52_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 33_344, housingAndMeals: 16_964, booksAndSupplies: 1_360, transportation: 1_900, personalExpenses: 2_200, averageGrantAid: 21_300),
            highlights: ["Washington, DC access", "Strong alumni network", "HBCU leadership legacy"]
        ),
        School(
            name: "University of Texas at Austin",
            city: "Austin",
            state: "TX",
            type: .publicUniversity,
            acceptanceRate: 0.29,
            graduationRate: 0.88,
            medianEarnings: 72_600,
            averageDebt: 21_100,
            studentCount: 53_082,
            campusVibe: "Big-city flagship with startup and research momentum.",
            programs: [
                Program(name: "Computer Science", credential: "BS", medianEarnings: 105_000, typicalDurationYears: 4),
                Program(name: "Advertising", credential: "BS", medianEarnings: 58_000, typicalDurationYears: 4),
                Program(name: "Petroleum Engineering", credential: "BS", medianEarnings: 112_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 11_698, housingAndMeals: 14_840, booksAndSupplies: 724, transportation: 1_682, personalExpenses: 3_032, averageGrantAid: 12_900),
            highlights: ["High earnings programs", "Austin internships", "Flagship campus resources"]
        ),
        School(
            name: "Santa Monica College",
            city: "Santa Monica",
            state: "CA",
            type: .communityCollege,
            acceptanceRate: 1.00,
            graduationRate: 0.36,
            medianEarnings: 42_400,
            averageDebt: 6_400,
            studentCount: 24_891,
            campusVibe: "Transfer-friendly, affordable, and close to creative industries.",
            programs: [
                Program(name: "Business Transfer", credential: "AA-T", medianEarnings: 48_000, typicalDurationYears: 2),
                Program(name: "Film Production", credential: "AA", medianEarnings: 44_000, typicalDurationYears: 2),
                Program(name: "Computer Science Transfer", credential: "AS-T", medianEarnings: 63_000, typicalDurationYears: 2)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 1_150, housingAndMeals: 18_500, booksAndSupplies: 1_080, transportation: 1_550, personalExpenses: 3_100, averageGrantAid: 5_500),
            highlights: ["Low tuition", "Strong UC transfer route", "Flexible schedules"]
        ),
        School(
            name: "Northeastern University",
            city: "Boston",
            state: "MA",
            type: .privateNonprofit,
            acceptanceRate: 0.07,
            graduationRate: 0.91,
            medianEarnings: 79_200,
            averageDebt: 25_900,
            studentCount: 30_013,
            campusVibe: "Urban, global, and built around co-op work experience.",
            programs: [
                Program(name: "Computer Engineering", credential: "BS", medianEarnings: 98_000, typicalDurationYears: 4),
                Program(name: "Health Science", credential: "BS", medianEarnings: 62_000, typicalDurationYears: 4),
                Program(name: "International Business", credential: "BSIB", medianEarnings: 82_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 63_141, housingAndMeals: 19_080, booksAndSupplies: 1_000, transportation: 900, personalExpenses: 1_200, averageGrantAid: 35_600),
            highlights: ["Co-op model", "Strong job placement", "Urban campus"]
        ),
        School(
            name: "Miami Dade College",
            city: "Miami",
            state: "FL",
            type: .communityCollege,
            acceptanceRate: 1.00,
            graduationRate: 0.34,
            medianEarnings: 39_800,
            averageDebt: 5_900,
            studentCount: 47_245,
            campusVibe: "Practical, local, and built for working students.",
            programs: [
                Program(name: "Nursing", credential: "ASN", medianEarnings: 67_000, typicalDurationYears: 2),
                Program(name: "Cybersecurity", credential: "AS", medianEarnings: 60_000, typicalDurationYears: 2),
                Program(name: "Business Administration", credential: "AA", medianEarnings: 44_000, typicalDurationYears: 2)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 2_838, housingAndMeals: 13_900, booksAndSupplies: 1_500, transportation: 1_600, personalExpenses: 2_900, averageGrantAid: 4_950),
            highlights: ["Very low tuition", "Workforce programs", "Multiple campuses"]
        ),
        School(
            name: "Reed College",
            city: "Portland",
            state: "OR",
            type: .liberalArts,
            acceptanceRate: 0.31,
            graduationRate: 0.79,
            medianEarnings: 60_100,
            averageDebt: 21_700,
            studentCount: 1_566,
            campusVibe: "Intellectual, intimate, and thesis-driven.",
            programs: [
                Program(name: "Mathematics", credential: "BA", medianEarnings: 71_000, typicalDurationYears: 4),
                Program(name: "English", credential: "BA", medianEarnings: 47_000, typicalDurationYears: 4),
                Program(name: "Biochemistry", credential: "BA", medianEarnings: 61_000, typicalDurationYears: 4)
            ],
            costEstimate: CostEstimate(tuitionAndFees: 67_020, housingAndMeals: 17_770, booksAndSupplies: 1_050, transportation: 900, personalExpenses: 1_500, averageGrantAid: 38_700),
            highlights: ["Small seminars", "Senior thesis culture", "Generous need-based aid"]
        )
    ]
}
