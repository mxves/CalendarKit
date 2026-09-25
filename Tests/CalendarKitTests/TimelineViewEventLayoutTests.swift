import XCTest
@testable import CalendarKit

final class TimelineViewEventLayoutTests: XCTestCase {
    private func attributes(_ startHour: Double, _ endHour: Double) -> EventLayoutAttributes {
        let event = Event()
        let midnight = Date(timeIntervalSinceReferenceDate: 0)
        event.dateInterval = DateInterval(start: midnight.addingTimeInterval(startHour * 3600),
                                          end: midnight.addingTimeInterval(endHour * 3600))
        return EventLayoutAttributes(event)
    }

    func testEventsAreFramedByTheirColumns() {
        let timeline = TimelineView(frame: CGRect(x: 0, y: 0, width: 353, height: 1200))
        let inset = timeline.style.leadingInset
        let width = timeline.calendarWidth

        timeline.layoutAttributes = [
            attributes(19.5, 20.5),
            attributes(20.5, 21.5),
            attributes(22, 23),
            attributes(22.5, 23.5),
        ]

        let frames = timeline.regularLayoutAttributes.map(\.frame)
        XCTAssertEqual(frames.map { Double($0.minX) }, [inset, inset, inset, inset + width / 2])
        XCTAssertEqual(frames.map { Double($0.width) }, [width, width, width / 2, width / 2])
    }
}
