import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "test") {
    let values = (1...100).publisher
    
    values
        .dropFirst(50)
        .prefix(20)
        .filter { $0 % 2 == 0 }
        .sink { print($0) }
        .store(in: &subscriptions)
}


