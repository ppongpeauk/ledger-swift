import Foundation

class DataManager: ObservableObject {
	@Published var transactions: [Transaction] = []
	@Published var recipients: [Recipient] = []
    
	private let transactionsKey = "saved_transactions"
	private let recipientsKey = "recipients"
    
	init() {
		loadTransactions()
		loadRecipients()
	}
    
	func loadTransactions() {
		if let data = UserDefaults.standard.data(forKey: transactionsKey),
		   let decoded = try? JSONDecoder().decode([Transaction].self, from: data)
		{
			transactions = decoded
		} else {
			transactions = []
		}
	}
    
	func saveTransactions() {
		if let encoded = try? JSONEncoder().encode(transactions) {
			UserDefaults.standard.set(encoded, forKey: transactionsKey)
			UserDefaults.standard.synchronize()
		}
	}
    
	func addTransaction(_ transaction: Transaction) {
		transactions.append(transaction)
		saveTransactions()
	}
    
	func deleteTransaction(at indexSet: IndexSet) {
		transactions.remove(atOffsets: indexSet)
		saveTransactions()
	}
    
	func addRecipient(_ recipient: Recipient) {
		recipients.append(recipient)
		saveRecipients()
	}
    
	func deleteRecipient(at indexSet: IndexSet) {
		// Get the recipients that are being deleted
		let recipientsToDelete = indexSet.map { recipients[$0] }
        
		// First update transactions
		var updatedTransactions = transactions
		var hasChanges = false
        
		for (index, transaction) in transactions.enumerated() {
			var updatedTransaction = transaction
			var splitUpdated = false
            
			updatedTransaction.splits = transaction.splits.map { split in
				var updatedSplit = split
				if recipientsToDelete.contains(where: { $0.id == split.recipientId }) {
					updatedSplit.recipientId = .empty
					splitUpdated = true
				}
				return updatedSplit
			}
            
			if splitUpdated {
				updatedTransactions[index] = updatedTransaction
				hasChanges = true
			}
		}
        
		// Update and save transactions if changes were made
		if hasChanges {
			DispatchQueue.main.async {
				self.transactions = updatedTransactions
				self.saveTransactions()
				self.objectWillChange.send()
			}
		}
        
		// Remove the recipients and save
		DispatchQueue.main.async {
			self.recipients.remove(atOffsets: indexSet)
			self.saveRecipients()
			self.objectWillChange.send()
            
			// Force UserDefaults to sync
			UserDefaults.standard.synchronize()
		}
	}
    
	func saveRecipients() {
		if let encoded = try? JSONEncoder().encode(recipients) {
			UserDefaults.standard.set(encoded, forKey: recipientsKey)
			UserDefaults.standard.synchronize()
		}
	}
    
	func loadRecipients() {
		if let data = UserDefaults.standard.data(forKey: recipientsKey),
		   let decoded = try? JSONDecoder().decode([Recipient].self, from: data)
		{
			DispatchQueue.main.async {
				self.recipients = decoded
				self.objectWillChange.send()
			}
		}
	}
}
