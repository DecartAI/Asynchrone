import Foundation

/// An async sequence that emits when a notification center broadcasts notifications.
///
/// ```swift
/// let sequence = NotificationCenterAsyncSequence(
///     notificationCenter: .default,
///     notificationName: UIDevice.orientationDidChangeNotification,
///     object: nil
/// )
///
/// for await element in sequence {
///     print(element)
/// }
///
/// ```
public struct NotificationCenterAsyncSequence: AsyncSequence {
    /// The kind of elements streamed.
    public typealias Element = Notification

    // Private
    private var notificationCenter: NotificationCenter
    private var notificationName: Notification.Name
    private var object: AnyObject?

    // MARK: Initialization

    public init(
        notificationCenter: NotificationCenter,
        notificationName: Notification.Name,
        object: AnyObject? = nil
    ) {
        self.notificationCenter = notificationCenter
        self.notificationName = notificationName
        self.object = object
    }
        
    // MARK: AsyncSequence
    
    /// Creates an async iterator that emits elements of this async sequence.
    /// - Returns: An instance that conforms to `AsyncIteratorProtocol`.
    public func makeAsyncIterator() -> Iterator {
        .init(
            notificationCenter: self.notificationCenter,
            notificationName: self.notificationName,
            object: self.object
        )
    }
}

// MARK: Iterator

extension NotificationCenterAsyncSequence {
    private struct UncheckedSendable<Value>: @unchecked Sendable {
        let value: Value
    }

    public struct Iterator: AsyncIteratorProtocol {
        private var notificationCenter: NotificationCenter
        private var passthroughAsyncSequence: PassthroughAsyncSequence<UncheckedSendable<Notification>> = .init()
        private var iterator: PassthroughAsyncSequence<UncheckedSendable<Notification>>.AsyncIterator
        private var observer: Any?
        
        // MARK: Initialization
        
        init(
            notificationCenter: NotificationCenter,
            notificationName: Notification.Name,
            object: AnyObject? = nil
        ) {
            self.notificationCenter = notificationCenter
            self.iterator = self.passthroughAsyncSequence.makeAsyncIterator()
            
            self.observer = self.notificationCenter.addObserver(
                forName: notificationName,
                object: object,
                queue: nil
            ) { [passthroughAsyncSequence] notification in
                passthroughAsyncSequence.yield(UncheckedSendable(value: notification))
            }
        }
        
        // MARK: AsyncIteratorProtocol
        
        public mutating func next() async -> Element? {
            guard let value = await self.iterator.next()?.value else {
                if let observer = observer {
                    self.notificationCenter.removeObserver(observer)
                }
                return nil
            }
            
            return value
        }
    }
}

// MARK: Notification center

extension NotificationCenter {
    /// Returns an async sequence that emits when the notification
    /// center broadcasts notifications.
    ///
    /// ```swift
    /// let sequence = NotificationCenter.default.sequence(for: UIDevice.orientationDidChangeNotification)
    ///
    /// for await element in sequence {
    ///     print(element)
    /// }
    ///
    /// ```
    public func sequence(
        for name: Notification.Name,
        object: AnyObject? = nil
    ) -> NotificationCenterAsyncSequence {
        .init(
            notificationCenter: self,
            notificationName: name,
            object: object
        )
    }
}
