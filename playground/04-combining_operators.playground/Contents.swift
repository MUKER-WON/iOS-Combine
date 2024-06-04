import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

/// emit의 제일 앞에 prepend 추가
example(of: "prepend(Output...)") {
    let publisher = [3, 4].publisher
    
    publisher
        .print()
        .prepend(0, 0, 3)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "prepend(Sequence)") {
    let publisher = [5, 6, 7].publisher
    
    publisher
        .prepend([3, 4])
        .prepend(Set(1...2)) // Set은 무작위 추출
        .prepend(-1,-2)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "prepend(Publisher)") {
    let publisher1 = [3, 4].publisher
    let publisher2 = [1, 2].publisher
    
    publisher1
        .prepend(publisher2)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// publisher2에 completion이 안들어오면 언제 끝나는지 모르기 때문에
/// publisher1는 출력되지 않는다.
example(of: "prepend(Publisher) #2") {
    let publisher1 = [3, 4].publisher
    let publisher2 = PassthroughSubject<Int, Never>()
    
    publisher1
        .prepend(publisher2)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    publisher2.send(1)
    publisher2.send(2)
    publisher2.send(completion: .finished)
}

example(of: "append(Output...)") {
    let publisher = [1].publisher
    
    publisher
        .append(2, 3)
        .append(4)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// 마찬가지로 append도 앞의 publisher가 끝나지 않은 상황이면
/// 추가적인 3,4,5가 출력되지 않는다.
example(of: "append(Output...) #2") {
    let publisher = PassthroughSubject<Int, Never>()
    
    publisher
        .append(3, 4)
        .append(5)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    publisher.send(1)
    publisher.send(2)
}

example(of: "append(Sequence)") {
    let publisher = [1, 2, 3].publisher
    
    publisher
        .append([4, 5]) // 2
        .append(Set([6, 7])) // 3
        .append(stride(from: 8, to: 11, by: 2)) // 4
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "append(Publisher)") {
    let publisher1 = [1, 2].publisher
    let publisher2 = [3, 4].publisher
    
    publisher1
        .append(publisher2)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// 마지막 publisher와 publishers 둘 다 complete가 되어야 completion 발동
example(of: "switchToLatest") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    let publisher3 = PassthroughSubject<Int, Never>()
    
    let publishers = PassthroughSubject<PassthroughSubject<Int,  Never>, Never>()
    
    publishers
        .switchToLatest()
        .sink(
            receiveCompletion: { _ in print("Completed!") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    
    publishers.send(publisher1)
    publisher1.send(1)
    publisher1.send(2)
    
    publishers.send(publisher2)
    publisher1.send(3)
    publisher2.send(4)
    publisher2.send(5)
    
    publishers.send(publisher3)
    publisher2.send(6)
    publisher3.send(7)
    publisher3.send(8)
    publisher3.send(9)
    
    publisher3.send(completion: .finished)
    publishers.send(completion: .finished)
}

/// 2번째와 3번째 event는 0.1초 밖에 차이나지 않아서
/// 2번째 event의 dataTaskPublisher가 완료되기 전에 3번째 event로 switch 되며
/// 2번재 작업은 무시된다.
example(of: "switchToLatest - Network Request") {
    let url = URL(
        string: "https://source.unsplash.com/random"
    )!
    
    func getImage() -> AnyPublisher<UIImage?, Never> {
        URLSession.shared
            .dataTaskPublisher(for: url)
            .map { data, _ in UIImage(data: data) }
            .print("image")
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    let taps = PassthroughSubject<Void, Never>()
    
    taps
        .map { _ in getImage() } // 3
        .switchToLatest() // 4
        .sink(receiveValue: { _ in print("receiveValue") })
        .store(in: &subscriptions)
    
    taps.send()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        taps.send()
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
        taps.send()
    }
}

/// 최대 8개의 merge 가능
example(of: "merge(with:)") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    
    publisher1
        .merge(with: publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    
    publisher1.send(1)
    publisher1.send(2)
    
    publisher2.send(3)
    
    publisher1.send(4)
    
    publisher2.send(5)
    
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

/// 서로 다른 type의 publisher도 결합 가능해서 유용
/// 결합된 publisher는 최소 하나의 값이 다 갖춰져있어야 방출
example(of: "combineLatest") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    
    publisher1
        .combineLatest(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \($0), P2: \($1)") }
        )
        .store(in: &subscriptions)
    
    publisher1.send(1)
    publisher1.send(2)
    
    publisher2.send("a")
    publisher2.send("b")
    
    publisher1.send(3)
    
    publisher2.send("c")
    
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

/// combineLatest와 다르게 zip은 send된 순서에 짝을 맞춰 tuple형태로 emit
example(of: "zip") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    
    publisher1
        .zip(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \($0), P2: \($1)") }
        )
        .store(in: &subscriptions)
    
    publisher1.send(1)
    publisher1.send(2)
    publisher2.send("a")
    publisher2.send("b")
    publisher1.send(3)
    publisher2.send("c")
    publisher2.send("d")
    publisher2.send("e")
    publisher1.send(4)
    
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

