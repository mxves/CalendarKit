import XCTest
@testable import CalendarKit

final class EventColumnLayoutTests: XCTestCase {
    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        Date(timeIntervalSinceReferenceDate: 0).addingTimeInterval(Double(hour * 3600 + minute * 60))
    }

    private func interval(_ start: (Int, Int), _ end: (Int, Int)) -> DateInterval {
        DateInterval(start: at(start.0, start.1), end: at(end.0, end.1))
    }

    private func column(_ index: Int, of count: Int, span: Int = 1) -> EventColumn {
        EventColumn(index: index, span: span, count: count)
    }

    func testBackToBackEventsStackAtFullWidth() {
        let columns = EventColumnLayout.columns(for: [
            interval((14, 0), (19, 30)),
            interval((19, 30), (20, 30)),
            interval((20, 30), (21, 30)),
            interval((22, 0), (23, 59)),
        ])

        XCTAssertEqual(columns, Array(repeating: column(0, of: 1), count: 4))
    }

    func testOverlappingEventsSplitTheWidth() {
        let columns = EventColumnLayout.columns(for: [
            interval((19, 0), (20, 0)),
            interval((19, 30), (20, 30)),
        ])

        XCTAssertEqual(columns, [column(0, of: 2), column(1, of: 2)])
    }

    func testAnEventReusesAColumnThatHasFreedUp() {
        let columns = EventColumnLayout.columns(for: [
            interval((7, 0), (8, 0)),
            interval((7, 30), (9, 0)),
            interval((8, 15), (9, 0)),
        ])

        XCTAssertEqual(columns, [column(0, of: 2), column(1, of: 2), column(0, of: 2)])
    }

    func testAnEventWidensIntoColumnsThatStayEmpty() {
        let columns = EventColumnLayout.columns(for: [
            interval((7, 0), (10, 0)),
            interval((7, 0), (8, 0)),
            interval((7, 0), (7, 30)),
            interval((8, 0), (9, 0)),
        ])

        XCTAssertEqual(columns, [
            column(0, of: 3),
            column(1, of: 3),
            column(2, of: 3),
            column(1, of: 3, span: 2),
        ])
    }

    func testTheLongerOfTwoEventsStartingTogetherTakesTheLeadingColumn() {
        let columns = EventColumnLayout.columns(for: [
            interval((7, 0), (8, 0)),
            interval((7, 0), (10, 0)),
        ])

        XCTAssertEqual(columns, [column(1, of: 2), column(0, of: 2)])
    }

    func testEachClusterGetsItsOwnColumnCount() {
        let columns = EventColumnLayout.columns(for: [
            interval((7, 0), (8, 0)),
            interval((7, 30), (8, 30)),
            interval((9, 0), (10, 0)),
        ])

        XCTAssertEqual(columns, [column(0, of: 2), column(1, of: 2), column(0, of: 1)])
    }

    /// Joins the cluster through an event that is neither the longest nor the
    /// latest one in it.
    func testAnEventOverlappingOnlyAMiddleEventJoinsItsCluster() {
        let intervals = [
            interval((13, 0), (16, 0)),
            interval((15, 0), (17, 30)),
            interval((15, 10), (15, 20)),
            interval((17, 0), (18, 0)),
        ]

        let columns = EventColumnLayout.columns(for: intervals)

        assertNoOverlapsShareAColumn(intervals, columns)
        XCTAssertEqual(columns[3].count, 3)
    }

    func testOverlappingEventsNeverShareAColumn() {
        var seed: UInt64 = 42
        func next(_ bound: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Int((seed >> 33) % UInt64(bound))
        }
        for _ in 0..<200 {
            let intervals = (0..<next(12)).map { _ -> DateInterval in
                let start = next(24 * 4) * 15
                let length = (1 + next(16)) * 15
                return DateInterval(start: at(0, start), duration: Double(length * 60))
            }

            let columns = EventColumnLayout.columns(for: intervals)

            XCTAssertEqual(columns.count, intervals.count)
            assertNoOverlapsShareAColumn(intervals, columns)
            for column in columns {
                XCTAssertTrue(column.index >= 0 && column.span >= 1 && column.index + column.span <= column.count)
            }
        }
    }

    func testNoEvents() {
        XCTAssertEqual(EventColumnLayout.columns(for: []), [])
    }

    private func assertNoOverlapsShareAColumn(_ intervals: [DateInterval],
                                              _ columns: [EventColumn],
                                              file: StaticString = #filePath,
                                              line: UInt = #line) {
        for a in intervals.indices {
            for b in intervals.indices where a < b && EventColumnLayout.overlaps(intervals[a], intervals[b]) {
                let lhs = columns[a], rhs = columns[b]
                XCTAssertEqual(lhs.count, rhs.count, "overlapping events \(a) and \(b) are in different clusters", file: file, line: line)
                let shared = lhs.index < rhs.index + rhs.span && rhs.index < lhs.index + lhs.span
                XCTAssertFalse(shared, "overlapping events \(a) and \(b) share a column: \(lhs) vs \(rhs)", file: file, line: line)
            }
        }
    }
}
