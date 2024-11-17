import SwiftUI

struct RecipientDetailView: View {
	let recipient: Recipient
	@Environment(\.dismiss) private var dismiss
	@Environment(\.dataManager) private var dataManager
	@State private var showingDeleteAlert = false
	@State private var showingRenameAlert = false
	@State private var newName = ""

	var recipientTransactions: [Transaction] {
		return dataManager.transactions.filter { transaction in
			transaction.splits.contains { split in
				split.recipientId == recipient.id
			}
		}
	}

	var body: some View {
		List {
			Section {
				if recipientTransactions.count > 0 {
					ForEach(recipientTransactions) { transaction in
						NavigationLink {
							TransactionDetailView(transaction: transaction)
						} label: {
							TransactionRowView(transaction: transaction, recipientId: recipient.id)
						}
					}
				} else {
					Text("No transactions yet.")
						.foregroundStyle(.secondary)
				}
			}
			Section {
				Button(
					role: .destructive,
					action: { showingDeleteAlert = true }
				) {
					Label {
						Text("Delete Recipient")
					} icon: {
						Image(systemName: "trash")
							.foregroundStyle(.red)
					}
				}
			}
		}
		.navigationTitle(recipient.name)
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button {
					newName = recipient.name
					showingRenameAlert = true
				} label: {
					Image(systemName: "pencil")
				}
			}
		}
		.refreshable {
			dataManager.loadTransactions()
			dataManager.objectWillChange.send()
		}
		.alert("Rename Recipient", isPresented: $showingRenameAlert) {
			TextField("Name", text: $newName)
			Button("Cancel", role: .cancel) {
				newName = ""
			}
			Button("Save") {
				if let index = dataManager.recipients.firstIndex(where: { $0.id == recipient.id }) {
					var updatedRecipient = recipient
					updatedRecipient.name = newName
					dataManager.recipients[index] = updatedRecipient
					dataManager.saveRecipients()
					dataManager.objectWillChange.send()
				}
				newName = ""
			}
			.disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
		}
		.confirmationDialog(
			"Delete Recipient",
			isPresented: $showingDeleteAlert
		) {
			Button("Delete", role: .destructive) {
				if let index = dataManager.recipients.firstIndex(where: { $0.id == recipient.id }) {
					dataManager.deleteRecipient(at: IndexSet(integer: index))
					dismiss()
				}
			}
		} message: {
			Text("Are you sure you want to delete '\(recipient.name)'? This action cannot be undone.")
		}
	}
}

private struct TransactionRowView: View {
	let transaction: Transaction
	let recipientId: UUID

	var body: some View {
		VStack(alignment: .leading) {
			Text(transaction.name)
			Text(formattedPrice)
				.foregroundStyle(.secondary)
		}
	}

	private var formattedPrice: String {
		let price = transaction.splits.first { $0.recipientId == recipientId }?.price ?? 0
		return String(format: "$%.2f", price)
	}
}

#Preview {
	NavigationStack {
		RecipientDetailView(
			recipient: Recipient(
				id: UUID(),
				name: "Test Recipient",
				dateAdded: Date()
			)
		)
		.environment(\.dataManager, DataManager())
	}
}
