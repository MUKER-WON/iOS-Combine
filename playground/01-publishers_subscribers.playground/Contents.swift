import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "1. Publisher") {
    let myNotification = Notification.Name("MyNotification")
    let center = NotificationCenter.default
    let publisher = center.publisher(
        for: myNotification,
        object: nil
    )
    let observer = center.addObserver(
        forName: myNotification,
        object: nil,
        queue: nil
    ) { notification in
        print("Notification received!")
    }
    center.post(
        name: myNotification,
        object: nil
    )
    center.removeObserver(observer)
}

example(of: "2. Subscriber") {
    let myNotification = Notification.Name("MyNotification")
    let center = NotificationCenter.default
    let publisher = center.publisher(
        for: myNotification,
        object: nil
    )
    let subscription = publisher.sink { _ in
        print("Notification received from a publisher!")
    }
    center.post(
        name: myNotification,
        object: nil
    )
    subscription.cancel()
}

example(of: "3. Just") {
    let just = Just("Hello world!")
    _ = just.sink(
        receiveCompletion: { completion in
            print("Received completion", completion)
        },
        receiveValue: { output in
            print("Received value", output)
        }
    )
}

example(of: "4. assign(to:on:)") {
    class SomeObject {
        var value: String = "" {
            didSet {
                print(value)
            }
        }
    }
    let object = SomeObject()
    let publisher = ["Hello", "World"].publisher
    _ = publisher.assign(
        to: \.value,
        on: object
    )
}

example(of: "5. assign(to:)") {
    class SomeObject {
        @Published var value = 0
    }
    let object = SomeObject()
    object.$value
        .sink {
            print($0)
        }
    (0..<10).publisher
        .assign(to: &object.$value)
}

example(of: "6. Custom Subscriber") {
    let publisher = [1,2,3,4,5].publisher
    
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never // 오류가 발생하지 않음을 명시할때 사용
        // 구독이 시작될 때 호출, 초기 데이터 요청을 수행
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            print("Received value:", input)
            return .max(1)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            print("Received completion:", completion)
        }
    }
    let subscriber = IntSubscriber()
    publisher.subscribe(subscriber)
}

example(of: "7. Future") {
    func futureIncrement(
        integer: Int,
        afterDelay delay: TimeInterval
    ) -> Future<Int, Never> {
        return Future<Int, Never> { promise in
            DispatchQueue.global().asyncAfter(
                deadline: .now() + delay,
                execute: {
                    promise(.success(integer + 1))
                }
            )
            print("Original")
        }
    }
    let future = futureIncrement(
        integer: 1,
        afterDelay: 0
    )
    future
        .sink(
            receiveCompletion: { print($0) },
            receiveValue: { print($0) }
        )
        .store(
            in: &subscriptions
        )
    future
        .sink(receiveCompletion: { print("Second", $0) },
              receiveValue: { print("Second", $0) })
        .store(in: &subscriptions)
}

example(of: "8. PassthroughSubject") {
    enum MyError: Error {
        case test
    }
    
    final class StringSubscriber: Subscriber {
        
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        func receive(_ input: String) -> Subscribers.Demand {
            print("Received value:", input)
            return input == "World" ? .max(1) : .none
        }
        
        func receive(completion: Subscribers.Completion<MyError>) {
            print("Received completion:", completion)
        }
    }
    
    let subscriber = StringSubscriber()
    // subject는 send를 받음
    let subject = PassthroughSubject<String, MyError>()
    subject.subscribe(subscriber)
    let subscription = subject
        .sink { completion in
            print("Received completion (sink):", completion)
        } receiveValue: { value in
            print("Received value (sink):", value)
        }
    subject.send("Hello")
    subject.send("World")
    subscription.cancel() // sink는 파괴
    subject.send("Still there?")
    subject.send(completion: .failure(MyError.test))
    subject.send(completion: .finished) // error가 나왔기때문에 안나옴
}

example(of: "9. CurrentValueSubject") {
    var subscriptions = Set<AnyCancellable>()
    let subject = CurrentValueSubject<Int, Never>(1)
    subject
        .print()
        .sink(
            receiveCompletion: { print($0) },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    subject.send(1)
    subject.send(2)
    subject.value = 3 // send와 똑같음
    subject
        .print()
        .sink { completion in
            print("Second complete:", completion)
        } receiveValue: { value in
            print("Second subscription:", value)
        }
    subject.send(4)
    subject.send(completion: .finished)
}

example(of: "10. Dynamically adjusting Demand") {
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never
        
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value:", input)
            switch input {
            case 1:
                return .max(2)
            case 3:
                return .max(1)
            default:
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    let subscriber = IntSubscriber()
    let subject = PassthroughSubject<Int, Never>()
    subject.subscribe(subscriber)
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(5)
    subject.send(6)
    // receive의 max는 추가적으로 더해진다.
}

example(of: "11. Type erasure") {
    let subject = PassthroughSubject<Int, Never>()
    let publisher = subject.eraseToAnyPublisher()
    publisher
        .sink(
            receiveCompletion: { print($0) },
            receiveValue: { print($0)} )
        .store(in: &subscriptions)
    subject.send(0)
}

example(of: "12. async/await") {
    let subject = CurrentValueSubject<Int, Never>(0)
    Task {
        for await element in subject.values {
            print("Element: \(element)")
        }
        print("Completed.")
    }
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(completion: .finished)
}
