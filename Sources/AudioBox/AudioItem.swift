import Foundation
import Combine

public final class AudioItem {

    public enum State {
        case initial, running, paused, stopped
    }

    public let id = UUID()
    @Published public private(set) var state: State = .initial
}

extension AudioItem {

    func attach(to action: AnyPublisher<AudioBox.PlaybackAction, Never>) -> AnyCancellable {
        action.sink { [unowned self] action in
            switch action {
            case .play:
                self.state = .running
            case .pause:
                self.state = .paused
            case .stop:
                self.state = .stopped
            }
        }
    }
}
