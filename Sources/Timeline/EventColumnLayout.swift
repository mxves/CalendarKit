import Foundation

/// Where an event sits among the events it overlaps.
struct EventColumn: Equatable {
    /// The column the event starts in, counting from the leading edge.
    var index: Int
    /// How many columns the event covers, starting at `index`.
    var span: Int
    /// How many columns its cluster is divided into.
    var count: Int
}

/// Side-by-side layout for the events of one day, the way Apple's and
/// Google's calendars do it.
///
/// Two events overlap only when one starts before the other ends, so an event
/// ending at 7:30 and one starting at 7:30 stack rather than share the width.
/// Events that overlap, directly or through a chain of overlaps, form a
/// cluster. Each event takes the first column that is free when it starts,
/// the cluster is divided into as many columns as it needs, and an event
/// widens into the columns to its right that stay empty for its whole span.
enum EventColumnLayout {
    /// One column per interval, in the order of `intervals`.
    static func columns(for intervals: [DateInterval]) -> [EventColumn] {
        // By start, then longest first, so a long event takes the leading
        // column and the short ones beside it sit to its right.
        let order = intervals.indices.sorted { a, b in
            let lhs = intervals[a], rhs = intervals[b]
            if lhs.start != rhs.start { return lhs.start < rhs.start }
            if lhs.end != rhs.end { return lhs.end > rhs.end }
            return a < b
        }

        var columns = [EventColumn](repeating: EventColumn(index: 0, span: 1, count: 1),
                                    count: intervals.count)
        var cluster: [Int] = []
        var clusterEnd = Date.distantPast
        for event in order {
            if !cluster.isEmpty && intervals[event].start >= clusterEnd {
                layOut(cluster: cluster, of: intervals, into: &columns)
                cluster.removeAll()
            }
            cluster.append(event)
            clusterEnd = max(clusterEnd, intervals[event].end)
        }
        layOut(cluster: cluster, of: intervals, into: &columns)
        return columns
    }

    static func overlaps(_ a: DateInterval, _ b: DateInterval) -> Bool {
        a.start < b.end && b.start < a.end
    }

    /// `cluster` is in layout order.
    private static func layOut(cluster: [Int],
                               of intervals: [DateInterval],
                               into columns: inout [EventColumn]) {
        // The end of the last event placed in each column. Events in a column
        // don't overlap and arrive in start order, so the last one ends last.
        var columnEnds: [Date] = []
        var placed: [(event: Int, column: Int)] = []
        for event in cluster {
            let interval = intervals[event]
            if let free = columnEnds.firstIndex(where: { $0 <= interval.start }) {
                columnEnds[free] = interval.end
                placed.append((event, free))
            } else {
                columnEnds.append(interval.end)
                placed.append((event, columnEnds.count - 1))
            }
        }

        let count = columnEnds.count
        for (event, column) in placed {
            var span = 1
            while column + span < count,
                  !placed.contains(where: { $0.column == column + span && overlaps(intervals[$0.event], intervals[event]) }) {
                span += 1
            }
            columns[event] = EventColumn(index: column, span: span, count: count)
        }
    }
}
