# AudioBox

**AudioBox** package implements audio playback and noise recording logic. It uses `AVAudioPlayer` as audio player and [NoiseRecorder](https://github.com/OlegPoliukhovych/NoiseRecorder) package as audio recorder.
This package uses **Combine** framework.

<!--## Contents-->
<!---->
<!--`AudioBox`. -->
<!--`AudioBox.ItemConfiguration`.-->
<!--`AudioBox.Event`. -->
<!--`AudioItem`.-->

## Usage

Public API is provided by two `AudioBox` instance methods:
- `func create(_ configuration: ItemConfiguration) -> AudioItem`, creates instance of `AudioItem` which is basically stores state that is usefull for observing from client's code e.g. to update UI. Internally it is paired with player or recorder instance according to `ItemConfiguration` parameter. Those objects also observing `AudioItem`'s state to perform actions like `play`, `pause`, `stop`.

- `func attach(eventPublisher: AnyPublisher<Event, Never>) -> AnyCancellable`, takes input publisher which will provide `Event`s that will be handled by AudioBox to control playback to currently active audio item as well setting audio item as current. 


``` swift
import AudioBox

let audioBox = AudioBox()
let url = ...audio file url
let audioItem = audioBox.create(.init(.playback(fileUrl: url, startTime: nil, isLooped: false)))
// audioItem.state == .initial

let eventPublisher = PassthroughSubject<AudioBox.Event, Never>()
let cancellable = audioBox.attach(eventPublisher: eventPublisher.eraseToAnyPublisher())

eventPublisher.send(AudioBox.Event.activate(audioItem))
// audioItem.state == .running

eventPublisher.send(AudioBox.Event.action(.pause))
// audioItem.state == .paused

let recordUrl: URL = ... recordings folder path
let recordItem = audioBox.create(.init(.record(destination: recordUrl)))

eventPublisher.send(AudioBox.Event.activate(recordItem))
// audioItem.state == .stopped
// recordItem.state == .running

```
