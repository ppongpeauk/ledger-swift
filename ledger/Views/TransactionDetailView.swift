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
	@State private var editedNote = ""
	
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
		.navigationTitle(transaction.name)
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button(isEditing ? "Save" : "Edit") {
					if isEditing {
						saveChanges()
					}
					isEditing.toggle()
				}
				.disabled(isEditing && !canSave)
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
			Text("Are you sure you want to delete '\(transaction.name)'? This action cannot be undone.")
		}
	}
	
	// MARK: - Sections
	
	private var detailsSection: some View {
		Section {
			if isEditing {
				TextField("Name", text: $editedName)
				ZStack(alignment: .topLeading) {
					if editedNote.isEmpty {
						Text("Add a note...")
							.foregroundColor(Color(.placeholderText))
							.padding(.vertical, 8)
					}
					TextEditor(text: $editedNote)
						.frame(minHeight: 100)
				}
			} else {
				LabeledContent("Name", value: transaction.name)
				if !transaction.note.isEmpty {
					LabeledContent("Note") {
						Text(transaction.note)
							.fixedSize(horizontal: false, vertical: true)
					}
				}
				LabeledContent("Total Amount", value: String(format: "$%.2f", totalAmount))
			}
		} header: {
			Text("Details")
		}
	}
	
	private var splitsSection: some View {
		Section {
			if editedSplits.isEmpty && !isEditing {
				Text("No splits")
					.foregroundStyle(.secondary)
			} else {
				ForEach(editedSplits.indices, id: \.self) { index in
					splitRow(at: index)
				}
				
				if isEditing {
					Button(action: {
						withAnimation {
							editedSplits.append(Split(recipientId: .empty, price: 0))
						}
					}) {
						Label("New Split", systemImage: "plus")
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
				HStack {
					Text("Tax")
					Spacer()
					TextField("Tax", text: $editedTax)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
				}
				HStack {
					Text("Tip")
					Spacer()
					TextField("Tip", text: $editedTip)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
				}
			} else {
				LabeledContent {
					Text(String(format: "$%.2f", transaction.extraPrices.tax))
				} label: {
					Text("Tax")
				}
				LabeledContent {
					Text(String(format: "$%.2f", transaction.extraPrices.tip))
				} label: {
					Text("Tip")
				}
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
			Button(role: .destructive, action: { showingDeleteAlert = true }) {
				Label {
					Text("Delete Transaction")
				} icon: {
					Image(systemName: "trash")
						.foregroundStyle(.red)
				}
			}
		}
	}
	
	// MARK: - Helper Views
	
	private func splitRow(at index: Int) -> some View {
		HStack {
			if isEditing {
				Picker("", selection: $editedSplits[index].recipientId) {
					Text("Unassigned").tag(UUID.empty)
					ForEach(dataManager.recipients) { recipient in
						Text(recipient.name).tag(recipient.id)
					}
				}
				.labelsHidden()
				.id(dataManager.recipients.count)

				Spacer()

				TextField("Amount", value: $editedSplits[index].price, format: .currency(code: "USD"))
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
					.frame(width: 120)

				if editedSplits.count > 1 {
					Button(role: .destructive) {
						withAnimation {
							editedSplits.removeAll { $0.id == editedSplits[index].id }
						}
					} label: {
						Image(systemName: "trash")
					}
					.buttonStyle(.borderless)
				}
			} else {
				if let recipient = dataManager.recipients.first(where: { $0.id == transaction.splits[index].recipientId }) {
					Text(recipient.name)
				} else {
					Text("Unassigned")
						.foregroundStyle(.secondary)
				}
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
	
	private var canSave: Bool {
		!editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
	
	// MARK: - Methods
	
	private func loadTransactionData() {
		editedName = transaction.name
		editedNote = transaction.note
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
			updatedTransaction.note = editedNote
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
				note: "",
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
