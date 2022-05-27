import AVFoundation
import Combine

extension AVAudioPlayer: AudioItemHandler {

    func prepare() {
        prepareToPlay()
    }

    func run() {
        play()
    }

    func finish() {
        stop()
    }
}

extension AVAudioPlayer {

    convenience init(fileUrl: URL, startTime: Date? = nil, isLooped: Bool = false) throws {
        try self.init(contentsOf: fileUrl)
        numberOfLoops = isLooped ? -1 : 0
        if let startDate = startTime {
            play(atTime: deviceCurrentTime + startDate.timeIntervalSinceNow)
        }
    }
}
