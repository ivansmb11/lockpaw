import XCTest
@testable import Lockpaw

final class ConstantsTests: XCTestCase {

    // MARK: - formatElapsedTime

    func testFormatElapsedTimeSecondsOnly() {
        XCTAssertEqual(Constants.formatElapsedTime(0), "0s")
        XCTAssertEqual(Constants.formatElapsedTime(5), "5s")
        XCTAssertEqual(Constants.formatElapsedTime(59), "59s")
    }

    func testFormatElapsedTimeMinutesAndSeconds() {
        XCTAssertEqual(Constants.formatElapsedTime(60), "1m 00s")
        XCTAssertEqual(Constants.formatElapsedTime(61), "1m 01s")
        XCTAssertEqual(Constants.formatElapsedTime(125), "2m 05s")
        XCTAssertEqual(Constants.formatElapsedTime(3599), "59m 59s")
    }

    func testFormatElapsedTimeHoursAndMinutes() {
        XCTAssertEqual(Constants.formatElapsedTime(3600), "1h 00m")
        XCTAssertEqual(Constants.formatElapsedTime(3660), "1h 01m")
        XCTAssertEqual(Constants.formatElapsedTime(7200), "2h 00m")
        XCTAssertEqual(Constants.formatElapsedTime(7325), "2h 02m")
    }

    // MARK: - formatWaitTime

    func testFormatWaitTime() {
        XCTAssertEqual(Constants.formatWaitTime(-1), "0s")
        XCTAssertEqual(Constants.formatWaitTime(0), "0s")
        XCTAssertEqual(Constants.formatWaitTime(59.9), "59s")
        XCTAssertEqual(Constants.formatWaitTime(60), "1m")
        XCTAssertEqual(Constants.formatWaitTime(3599), "59m")
        XCTAssertEqual(Constants.formatWaitTime(3660), "1h 01m")
    }

    func testWaitTimeTicksEverySecondThenOnTheMinute() {
        let start = Date(timeIntervalSince1970: 1_000)
        func next(_ elapsed: TimeInterval) -> TimeInterval {
            Constants.nextWaitTimeChange(after: start.addingTimeInterval(elapsed), since: start)
                .timeIntervalSince(start)
        }
        XCTAssertEqual(next(0), 1)
        XCTAssertEqual(next(0.4), 1)
        XCTAssertEqual(next(58.5), 59)
        XCTAssertEqual(next(59), 60)
        XCTAssertEqual(next(60), 120)
        XCTAssertEqual(next(150), 180)
    }

    // MARK: - formatElapsedTimeAccessible

    func testFormatElapsedTimeAccessibleSecondsOnly() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(0), "0 seconds")
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(5), "5 seconds")
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(59), "59 seconds")
    }

    func testFormatElapsedTimeAccessibleSingularSecond() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(1), "1 second")
    }

    func testFormatElapsedTimeAccessibleMinutesAndSeconds() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(60), "1 minute 0 seconds")
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(61), "1 minute 1 second")
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(125), "2 minutes 5 seconds")
    }

    func testFormatElapsedTimeAccessibleSingularMinute() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(60), "1 minute 0 seconds")
    }

    func testFormatElapsedTimeAccessiblePluralMinutes() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(120), "2 minutes 0 seconds")
    }

    func testFormatElapsedTimeAccessibleHoursAndMinutes() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(3600), "1 hour 0 minutes")
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(3660), "1 hour 1 minute")
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(7200), "2 hours 0 minutes")
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(7325), "2 hours 2 minutes")
    }

    func testFormatElapsedTimeAccessibleSingularHour() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(3600), "1 hour 0 minutes")
    }

    func testFormatElapsedTimeAccessiblePluralHours() {
        XCTAssertEqual(Constants.formatElapsedTimeAccessible(7200), "2 hours 0 minutes")
    }
}
