import Foundation

public func example(of description: String, action: () -> Void) {
  print("\n--- Example of:", description, "---")
  action()
}

example(of: "just, of, from"){
    let one = 1
    let two = 2
    let three = 3
//    let observable: Observable<Int> = Observable<Int>.just(one)
}
