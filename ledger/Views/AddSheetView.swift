import SwiftUI
import UserNotifications

struct AddSheetView: View {
	@Binding var addSheetShown: Bool
	@ObservedObject var dataManager: DataManager

	@State private var name: String = ""
	@State private var splits: [Split] = [Split(recipientId: UUID(), price: 0)]
	@State private var tax: String = "0"
	@State private var tip: String = "0"
	@State private var notificationEnabled = false
	@State private var notificationDate = Date()

	private var isValid: Bool {
		!name.isEmpty &&
			!splits.isEmpty &&
			splits.allSatisfy { $0.price > 0 } &&
			(Double(tax) ?? 0) >= 0 &&
			(Double(tip) ?? 0) >= 0
	}

	var body: some View {
		NavigationView {
			Form {
				transactionDetailsSection
				splitsSection
				additionalChargesSection
				reminderSection
			}
			.navigationTitle("New Transaction")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						addSheetShown = false
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Add") {
						addTransaction()
					}
					.disabled(!isValid)
				}
			}
		}
	}

	private var transactionDetailsSection: some View {
		Section(header: Text("Transaction Details")) {
			TextField("Name", text: $name)
		}
	}

	private var splitsSection: some View {
		Section(header: Text("Splits")) {
			ForEach($splits) { $split in
				HStack {
					TextField("Amount", value: $split.price, format: .currency(code: "USD"))
						.keyboardType(.decimalPad)

					if splits.count > 1 {
						Button(role: .destructive) {
							withAnimation {
								splits.removeAll { $0.id == split.id }
							}
						} label: {
							Image(systemName: "trash")
						}
					}
				}
			}

			Button("Add Split") {
				withAnimation {
					splits.append(Split(recipientId: UUID(), price: 0))
				}
			}
		}
	}

	private var additionalChargesSection: some View {
		Section(header: Text("Additional Charges")) {
			HStack {
				Text("Tax")
				Spacer()
				TextField("Tax", value: Binding(
					get: { Double(tax) ?? 0 },
					set: { tax = String($0) }
				), format: .currency(code: "USD"))
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
			}
			HStack {
				Text("Tip")
				Spacer()
				TextField("Tip", value: Binding(
					get: { Double(tip) ?? 0 },
					set: { tip = String($0) }
				), format: .currency(code: "USD"))
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
			}
		}
	}

	private var reminderSection: some View {
		Section(header: Text("Reminder")) {
			Toggle("Set Reminder", isOn: $notificationEnabled)
			if notificationEnabled {
				DatePicker("Reminder Time",
				           selection: $notificationDate,
				           displayedComponents: [.date, .hourAndMinute])
			}
		}
	}

	private func addTransaction() {
		let transaction = Transaction(
			id: UUID(),
			name: name,
			notification: notificationEnabled ? TransactionNotification(
				name: "Payment Reminder for \(name)",
				time: notificationDate
			) : nil,
			splits: splits,
			extraPrices: ExtraPrices(
				tax: Double(tax) ?? 0,
				tip: Double(tip) ?? 0
			)
		)

		dataManager.addTransaction(transaction)

		if notificationEnabled {
			scheduleNotification(for: transaction)
		}

		addSheetShown = false
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

#Preview {
	NavigationStack {
		AddSheetView(
			addSheetShown: .constant(true),
			dataManager: DataManager()
		)
	}
}
