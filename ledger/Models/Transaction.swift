import Foundation

struct Transaction: Identifiable, Codable {
	let id: UUID
	var name: String
	var notification: TransactionNotification?
	var splits: [Split]
	var extraPrices: ExtraPrices
	
	// Add any additional properties you might need
}

struct TransactionNotification: Codable {
	var name: String
	var time: Date
}

struct Split: Identifiable, Codable {
	var id: UUID
	var recipientId: UUID
	var price: Double
	
	init(recipientId: UUID, price: Double) {
		self.id = UUID()
		self.recipientId = recipientId
		self.price = price
	}
}

struct ExtraPrices: Codable {
	var tax: Double
	var tip: Double
}
