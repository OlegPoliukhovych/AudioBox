import Combine
import AVFAudio
import NoiseRecorder

public final class AudioBox {

    public struct ItemConfiguration {
        public enum Mode {
            case playback(fileUrl: URL, startTime: Date?, isLooped: Bool = false)
            case record(destination: URL)
        }

        public let mode: Mode

        public init(_ mode: Mode) {
            self.mode = mode
        }
    }

    public enum Event {
        case activate(AudioItem)
        case action(PlaybackAction)
        case deactivateSession
    }

    public enum PlaybackAction {
        case play, pause, stop
    }

    @Published public private(set) var currentAudioItem: AudioItem?
    private var eventPublisher: AnyPublisher<Event, Never>?
    private var action = PassthroughSubject<PlaybackAction, Never>()
    private var audioItemHandlers = [UUID: AudioItemHandler]()
    private var cancellables = Set<AnyCancellable>()
    private var audioItemCancellable: AnyCancellable?
    private var itemHandlerCancellable: AnyCancellable?

    public init() {

        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)

        $currentAudioItem
            .scan(nil) { [unowned self] prev, next in
                if let item = prev {
                    cancel(item)
                }
                return next
            }
            .compactMap { $0 }
            .sink { [unowned self] in setup($0) }
            .store(in: &cancellables)
    }

    public func create(_ configuration: ItemConfiguration) -> AudioItem {
        let audioItem = AudioItem()
        audioItemHandlers[audioItem.id] = audioItemHandler(configuration)
        return audioItem
    }

    public func attach(eventPublisher: AnyPublisher<Event, Never>) -> AnyCancellable {
        eventPublisher
            .merge(with: AVAudioSession.sharedInstance()
                .interruptionPublisher
                .compactMap { interruption -> AudioBox.Event? in
                    switch interruption {
                    case .began:
                        return .action(.pause)
                    case .ended(shouldResume: let shouldResume) where shouldResume == true:
                        return .action(.play)
                    case .ended(shouldResume: _):
                        return nil
                    }
                })
            .sink { [weak self] event in
                switch event {
                case .activate(let audioItem):
                    self?.currentAudioItem = audioItem
                case .action(let _action):
                    self?.action.send(_action)
                case .deactivateSession:
                    self?.cleanup()
                }
            }
    }

    private func setup(_ audioItem: AudioItem) {
        audioItemCancellable = audioItem.attach(to: action.eraseToAnyPublisher())
        itemHandlerCancellable = audioItemHandlers[audioItem.id]?.attach(to: audioItem.$state.eraseToAnyPublisher())
        action.send(.play)
    }

    private func cancel(_ audioItem: AudioItem) {
        action.send(.stop)
        audioItemCancellable = nil
        itemHandlerCancellable = nil
        audioItemHandlers[audioItem.id] = nil
    }

    private func cleanup() {
        currentAudioItem = nil
        audioItemHandlers.removeAll()
    }
}

private extension AudioBox {

    func audioItemHandler(_ configuration: ItemConfiguration) -> AudioItemHandler? {

        switch configuration.mode {
        case .playback(fileUrl: let url, startTime: let date, isLooped: let looped):
            return try? AVAudioPlayer(fileUrl: url, startTime: date, isLooped: looped)
        case .record(destination: let url):
            let recorder = NoiseRecorder(pathGenerator: { url.appendingPathComponent(UUID().uuidString) })
            // activate audio engine immediately in foreground because there will be error if do so later from background
            // smells bad but this seems to be known behavior.
            // so it will take audio input but ignore it until it is actually needed.
            recorder.activateAudioEngine()
            return recorder
        }
    }
}

private extension AudioItemHandler {

    func attach(to state: AnyPublisher<AudioItem.State, Never>) -> AnyCancellable {
        state.sink { _state in
            switch _state {
            case .initial:
                prepare()
            case .running:
                run()
            case .paused:
                pause()
            case .stopped:
                stop()
            }
        }
    }
}

extension NoiseRecorder: AudioItemHandler { }
