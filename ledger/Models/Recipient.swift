import Foundation

struct Recipient: Identifiable, Codable {
	let id: UUID
	var name: String
	let dateAdded: Date
}
