import Foundation

struct Transaction: Identifiable, Codable, Equatable {
	let id: UUID
	var name: String
	var note: String
	var notification: TransactionNotification?
	var splits: [Split]
	var extraPrices: ExtraPrices
}

struct TransactionNotification: Codable, Equatable {
	var name: String
	var time: Date
}

struct Split: Identifiable, Codable, Equatable {
	var id: UUID
	var recipientId: UUID
	var price: Double

	init(recipientId: UUID, price: Double) {
		self.id = UUID()
		self.recipientId = recipientId
		self.price = price
	}
}

struct ExtraPrices: Codable, Equatable {
	var tax: Double
	var tip: Double
}
