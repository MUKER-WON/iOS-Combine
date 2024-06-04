import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "filter") {
    let numbers = (1...10).publisher
    numbers
        .filter { $0.isMultiple(of: 3) }
        .sink(receiveValue: { print("\($0)은 3의 배수") })
        .store(in: &subscriptions)
}

/// 연속되는 value 삭제
example(of: "removeDuplicates") {
    let words = "안녕하세요 반갑습니다 반갑습니다 처음 뵙겠습니다 반갑습니다"
        .components(separatedBy: " ")
        .publisher
    
    words
        .removeDuplicates()
        .sink { value in
            print("\(value)")
        }
        .store(in: &subscriptions)
}

/// 클로저 안에 nil로 return되는 건 걸러줌
example(of: "compactMap") {
    let strings = ["a", "1.24", "3", "def", "45", "0.23"]
        .publisher
    
    strings
        .compactMap { string in
            Float(string)
        }
        .sink { print($0) }
        .store(in: &subscriptions)
}

/// 값이 방출되는건 무시하고 오직 completion이벤트만 발생
example(of: "ignoreOutput") {
    let numbers = (1...10_000).publisher
    
    numbers
        .ignoreOutput()
        .sink(
            receiveCompletion: { print("completion: \($0)") },
            receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// 하나만 찾고 complete
example(of: "first(where:)") {
    let numbers = (1...9).publisher
    
    numbers
        .print("print")
        .first(where: { $0 % 2 == 0 })
        .sink(
            receiveCompletion: { print("Completed with: \($0)") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
}

example(of: "last(where:)") {
    let numbers = (1...9).publisher
    
    numbers
        .last(where: { $0 % 2 == 0 } )
        .sink(
            receiveCompletion: { print("Completed with: \($0)") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
}

/// completion이 작동되지 않아 언제 끝날지 모르기 때문에 where에 합당한 숫자가 들어와도
/// receive 되지 않음
example(of: "last(where:)") {
    let numbers = PassthroughSubject<Int, Never>()
    
    numbers
        .print()
        .last(where: { $0 % 2 == 0 } )
        .sink(
            receiveCompletion: { print("Completed with: \($0)") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    
    numbers.send(1)
    numbers.send(2)
    numbers.send(3)
    numbers.send(4)
    numbers.send(5)
    numbers.send(completion: .finished)
}

example(of: "dropFirst") {
    let numbers = (1...10).publisher
    
    numbers
        .dropFirst(8)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "drop(while:)") {
    let numbers = (1...10).publisher
    
    numbers
        .drop(while: { value in
            print(value)
            return value % 5 != 0
        })
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/// isReady에 value가 들어온순간 drop 시작
example(of: "drop(untilOutputFrom:)") {
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    taps
        .drop(untilOutputFrom: isReady)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    (1...5).forEach { n in
        taps.send(n)
        
        if n == 3 {
            isReady.send()
        }
    }
}

/// prefix(2)는 앞의 두개의 값만 emit하고 complete
example(of: "prefix") {
    let numbers = (1...10).publisher
    
    numbers
        .prefix(2)
        .sink(
            receiveCompletion: { print("Completed with: \($0)") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
}

example(of: "prefix(while:)") {
    let numbers = (1...10).publisher
    
    numbers
        .prefix(while: { $0 < 3 })
        .sink(
            receiveCompletion: { print("Completed with: \($0)") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
}

example(of: "prefix(untilOutputFrom:)") {
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    taps
        .prefix(untilOutputFrom: isReady)
        .sink(
            receiveCompletion: { print("Completed with: \($0)") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    
    (1...5).forEach { n in
        taps.send(n)
        
        if n == 2 {
            isReady.send()
        }
    }
}

