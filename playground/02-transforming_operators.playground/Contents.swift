import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "collect") {
    ["A","B","C","D","E"].publisher
        .collect(2)
        .sink { completion in
            print(completion)
        } receiveValue: { value in
            print(value)
        }
        .store(in: &subscriptions)
}

example(of: "map") {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    [123, 4, 56].publisher
        .map {
            formatter.string(from: NSNumber(value: $0)) ?? ""
        }
        .sink { completion in
            print(completion)
        } receiveValue: { value in
            print(value)
        }
        .store(in: &subscriptions)
}

example(of: "mapping key paths") {
    let publisher = PassthroughSubject<Coordinate, Never>()
    publisher
        // 객체의 속성에 대해 각각의 값을 변환할 수 있음
        .map(\Coordinate.x, \Coordinate.y)
        .sink { completion in
            print(completion)
        } receiveValue: { x,y in
            print(quadrantOf(x: x, y: y))
        }
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(.init(x: 0, y: 5))
}

example(of: "tryMap") {
    Just("Directory name that does not exist")
        .tryMap {
            try FileManager.default.contentsOfDirectory(
                atPath: $0
            )
        }
        .sink { completion in
            print(completion)
        } receiveValue: { value in
            print(value)
        }
        .store(in: &subscriptions)

}

example(of: "flatMap") {
    // flatMap은 여러 upstream publisher를 하나의 publisher로 만든다.
    // 즉 방출값을 flat하게 만든다.
    func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
        Just(
            codes
                .compactMap { code in
                    guard (32...255).contains(code) else { return nil }
                    return String(UnicodeScalar(code) ?? " ")
                }
                .joined()
        )
        .eraseToAnyPublisher()
    }
    
    [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
        .publisher
        .collect()
        .flatMap(decode)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "replaceNil") {
    ["A", nil, "C"]
        .publisher
        .eraseToAnyPublisher()
        .replaceNil(with: "-")
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "replaceEmpty(with:)") {
    let empty = Empty<Int, Never>()
    empty
        .replaceEmpty(with: 1)
        .sink(
            receiveCompletion: { print($0) },
            receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "scan") {
  var dailyGainLoss: Int { .random(in: -10...10) }
  let august2019 = (0..<22)
        .map { _ in
            return dailyGainLoss
        }
    .publisher
  august2019
    .scan(50) { latest, current in
      max(0, latest + current)
    }
    .sink(receiveValue: { _ in })
    .store(in: &subscriptions)
}
