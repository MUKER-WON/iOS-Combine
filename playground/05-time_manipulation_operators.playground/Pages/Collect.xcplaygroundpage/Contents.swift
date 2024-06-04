import Combine
import SwiftUI
import PlaygroundSupport

let valuesPerSecond = 1.0
let collectTimeStride = 4

let sourcePublisher = PassthroughSubject<Date, Never>()

/// collect로 시간만큼 모았다가 emit
let collectedPublisher = sourcePublisher
    .collect(
        .byTime(
            DispatchQueue.main,
            .seconds(collectTimeStride)
        )
    )
    .flatMap({ dates in dates.publisher })

let subscription = Timer
    .publish(
        every: 1.0 / valuesPerSecond,
        on: .main, in: .common
    )
    .autoconnect()
    .subscribe(sourcePublisher)

let collectMaxCount = 2

let collectedPublisher2 = sourcePublisher
    .collect(
        .byTimeOrCount(
            DispatchQueue.main,
            .seconds(collectTimeStride),
            collectMaxCount
        )
    )
    .flatMap { dates in dates.publisher }

let sourceTimeline = TimelineView(title: "Emitted values:")
let collectedTimeline = TimelineView(title: "Collected values (every \(collectTimeStride)s):")
let collectedTimeline2 = TimelineView(title: "Collected values (at most \(collectMaxCount) every \(collectTimeStride)s):")


let view = VStack(spacing: 40) {
    sourceTimeline
    collectedTimeline
    collectedTimeline2
}

PlaygroundPage.current.liveView = UIHostingController(
    rootView: view.frame(width: 375, height: 600)
)

sourcePublisher.displayEvents(in: sourceTimeline)
collectedPublisher.displayEvents(in: collectedTimeline)
collectedPublisher2.displayEvents(in: collectedTimeline2)


