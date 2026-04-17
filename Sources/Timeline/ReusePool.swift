import UIKit

final class ReusePool<T: UIView> {
    private var storage: [T]
    private let factory: (() -> T)?

    init(factory: (() -> T)? = nil) {
        self.factory = factory
        self.storage = [T]()
    }

    func enqueue(views: [T]) {
        views.forEach{$0.frame = .zero}
        storage.append(contentsOf: views)
    }

    func dequeue() -> T {
        guard !storage.isEmpty else {
            return factory?() ?? T()
        }
        return storage.removeLast()
    }
}
