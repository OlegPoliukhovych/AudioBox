import AVFoundation
import Combine

extension AVAudioSession {

    enum Interruption: Equatable {
        case began
        case ended(shouldResume: Bool)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.began, .ended(_)),
                 (.ended(_), .began):
                return false
            case (.ended(let ended1), .ended(let ended2)):
                return ended1 != ended2
            case (.began, .began):
                return true
            }
        }
    }

    var interruptionPublisher: AnyPublisher<Interruption, Never> {
        NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .compactMap({ notification -> AVAudioSession.Interruption? in
                guard let userInfo = notification.userInfo,
                    let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                    let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                        return nil
                }

                switch type {
                case .began:
                    return .began
                case .ended:
                    guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return .ended(shouldResume: false) }
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    return .ended(shouldResume: options.contains(.shouldResume))
                @unknown default:
                    return nil
                }
            })
            .eraseToAnyPublisher()
    }
}
