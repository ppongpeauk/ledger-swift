import SwiftUI
import UserNotifications

struct TransactionDetailView: View {
	let transaction: Transaction
	@Environment(\.dismiss) private var dismiss
	@Environment(\.dataManager) private var dataManager
	
	// View States
	@State private var isEditing = false
	@State private var showingDeleteAlert = false
	
	// Form States
	@State private var editedName = ""
	@State private var editedSplits: [Split] = []
	@State private var editedTax = ""
	@State private var editedTip = ""
	@State private var notificationEnabled = false
	@State private var notificationDate = Date()
	
	var body: some View {
		List {
			detailsSection
			splitsSection
			additionalChargesSection
			reminderSection
			
			if !isEditing {
				deleteSection
			}
		}
		.navigationTitle("Transaction Details")
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button(isEditing ? "Save" : "Edit") {
					if isEditing {
						saveChanges()
					}
					isEditing.toggle()
				}
			}
		}
		.onAppear {
			loadTransactionData()
		}
		.confirmationDialog(
			"Delete Transaction",
			isPresented: $showingDeleteAlert
		) {
			Button("Delete", role: .destructive) {
				deleteTransaction()
			}
		} message: {
			Text("Are you sure you want to delete this transaction?")
		}
	}
	
	// MARK: - Sections
	
	private var detailsSection: some View {
		Section {
			if isEditing {
				TextField("Name", text: $editedName)
			} else {
				LabeledContent("Name", value: transaction.name)
				LabeledContent("Total Amount", value: String(format: "$%.2f", totalAmount))
			}
		} header: {
			Text("Details")
		}
	}
	
	private var splitsSection: some View {
		Section {
			ForEach(editedSplits.indices, id: \.self) { index in
				splitRow(at: index)
			}
			
			if isEditing {
				Button("Add Split") {
					withAnimation {
						editedSplits.append(Split(recipientId: UUID(), price: 0))
					}
				}
			}
		} header: {
			Text("Splits")
		}
	}
	
	private var additionalChargesSection: some View {
		Section {
			if isEditing {
				TextField("Tax", text: $editedTax)
					.keyboardType(.decimalPad)
				TextField("Tip", text: $editedTip)
					.keyboardType(.decimalPad)
			} else {
				LabeledContent("Tax", value: String(format: "$%.2f", transaction.extraPrices.tax))
				LabeledContent("Tip", value: String(format: "$%.2f", transaction.extraPrices.tip))
			}
		} header: {
			Text("Additional Charges")
		}
	}
	
	private var reminderSection: some View {
		Section {
			Toggle("Set Reminder", isOn: $notificationEnabled)
			if notificationEnabled {
				DatePicker(
					"Reminder Time",
					selection: $notificationDate,
					displayedComponents: [.date, .hourAndMinute]
				)
			}
		} header: {
			Text("Reminder")
		}
	}
	
	private var deleteSection: some View {
		Section {
			Button("Delete Transaction", role: .destructive) {
				showingDeleteAlert = true
			}
		}
	}
	
	// MARK: - Helper Views
	
	private func splitRow(at index: Int) -> some View {
		HStack {
			if isEditing {
				TextField("Amount", text: Binding(
					get: { String(format: "%.2f", editedSplits[index].price) },
					set: { if let value = Double($0) { editedSplits[index].price = value } }
				))
				.keyboardType(.decimalPad)
					
				if editedSplits.count > 1 {
					Button(role: .destructive) {
						withAnimation {
							let splitToRemove = editedSplits[index]
							editedSplits.removeAll { $0.id == splitToRemove.id }
						}
					} label: {
						Image(systemName: "trash")
					}
				}
			} else {
				Text("Amount")
				Spacer()
				Text(String(format: "$%.2f", transaction.splits[index].price))
			}
		}
	}
	
	// MARK: - Computed Properties
	
	private var totalAmount: Double {
		let splitTotal = editedSplits.reduce(0) { $0 + $1.price }
		return splitTotal + (Double(editedTax) ?? 0) + (Double(editedTip) ?? 0)
	}
	
	// MARK: - Methods
	
	private func loadTransactionData() {
		editedName = transaction.name
		editedSplits = transaction.splits
		editedTax = String(format: "%.2f", transaction.extraPrices.tax)
		editedTip = String(format: "%.2f", transaction.extraPrices.tip)
		notificationEnabled = transaction.notification != nil
		if let notification = transaction.notification {
			notificationDate = notification.time
		}
	}
	
	private func saveChanges() {
		if let index = dataManager.transactions.firstIndex(where: { $0.id == transaction.id }) {
			var updatedTransaction = transaction
			updatedTransaction.name = editedName
			updatedTransaction.splits = editedSplits
			updatedTransaction.extraPrices = ExtraPrices(
				tax: Double(editedTax) ?? 0,
				tip: Double(editedTip) ?? 0
			)
			
			if notificationEnabled {
				updatedTransaction.notification = TransactionNotification(
					name: "Payment Reminder for \(editedName)",
					time: notificationDate
				)
				scheduleNotification(for: updatedTransaction)
			} else {
				updatedTransaction.notification = nil
			}
			
			dataManager.transactions[index] = updatedTransaction
			dataManager.saveTransactions()
		}
	}
	
	private func deleteTransaction() {
		if let index = dataManager.transactions.firstIndex(where: { $0.id == transaction.id }) {
			dataManager.deleteTransaction(at: IndexSet(integer: index))
			dismiss()
		}
	}
	
	private func scheduleNotification(for transaction: Transaction) {
		guard let notification = transaction.notification else { return }
		
		let content = UNMutableNotificationContent()
		content.title = "Payment Reminder"
		content.body = "Payment due for: \(transaction.name)"
		content.sound = .default
		
		let components = Calendar.current.dateComponents(
			[.year, .month, .day, .hour, .minute],
			from: notification.time
		)
		let trigger = UNCalendarNotificationTrigger(
			dateMatching: components,
			repeats: false
		)
		
		let request = UNNotificationRequest(
			identifier: transaction.id.uuidString,
			content: content,
			trigger: trigger
		)
		
		UNUserNotificationCenter.current().add(request)
	}
}

// MARK: - Preview

#Preview {
	NavigationStack {
		TransactionDetailView(
			transaction: Transaction(
				id: UUID(),
				name: "Test Transaction",
				notification: TransactionNotification(
					name: "Payment Due",
					time: Date()
				),
				splits: [
					Split(recipientId: UUID(), price: 25.0),
					Split(recipientId: UUID(), price: 15.0)
				],
				extraPrices: ExtraPrices(tax: 3.20, tip: 8.0)
			)
		)
		.environment(\.dataManager, DataManager())
	}
}
