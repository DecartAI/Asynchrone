public struct UnsafeSendable<Value>: @unchecked Sendable {
	public let value: Value

	public init(_ value: Value) {
		self.value = value
	}
}
