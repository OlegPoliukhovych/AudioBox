import XCTest
@testable import AudioBox
import Combine

final class AudioBoxTests: XCTestCase {

    let audioBox = AudioBox()
    var audioItem: AudioItem!
    let eventPublisher = PassthroughSubject<AudioBox.Event, Never>()
    var eventPublisherCancellable: AnyCancellable?

    override func setUp() {
        audioItem = audioBox.create(configPlayback(natureUrl))
        eventPublisherCancellable = audioBox.attach(eventPublisher: eventPublisher.eraseToAnyPublisher())
    }

    override func tearDown() {
        eventPublisherCancellable?.cancel()
        eventPublisherCancellable = nil
    }

    var natureUrl: URL {
        let path = Bundle.module.path(forResource: "nature.m4a", ofType: nil)
        return URL(fileURLWithPath: path!)
    }

    var alarmUrl: URL {
        let path = Bundle.module.path(forResource: "alarm.m4a", ofType: nil)
        return URL(fileURLWithPath: path!)
    }

    func configPlayback(_ url: URL) -> AudioBox.ItemConfiguration {
        .init(.playback(fileUrl: url, startTime: nil, isLooped: false))
    }

    func testAudioItemAssignment() {
        eventPublisher.send(.activate(audioItem))

        XCTAssertNotNil(audioBox.currentAudioItem)
    }

    func testAudioItemPlay() {

        eventPublisher.send(.activate(audioItem))
        eventPublisher.send(.action(.play))

        XCTAssert(audioItem.state == .running)
    }

    func testAudioItemPause() {

        eventPublisher.send(.activate(audioItem))
        eventPublisher.send(.action(.pause))

        XCTAssert(audioItem.state == .paused)
    }

    func testAudioItemStop() {

        eventPublisher.send(.activate(audioItem))
        eventPublisher.send(.action(.stop))

        XCTAssert(audioItem.state == .stopped)
    }

    func testSessionCleanup() {

        eventPublisher.send(.activate(audioItem))
        eventPublisher.send(.deactivateSession)

        XCTAssert(audioBox.currentAudioItem == nil)
    }
}
