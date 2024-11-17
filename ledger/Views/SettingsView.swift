//
//  SettingsView.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

let context = CIContext()
let filter = CIFilter.qrCodeGenerator()

func getQRCodeDate(text: String) -> Data? {
	guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
	let data = text.data(using: .ascii, allowLossyConversion: false)
	filter.setValue(data, forKey: "inputMessage")
	guard let ciimage = filter.outputImage else { return nil }
	let transform = CGAffineTransform(scaleX: 10, y: 10)
	let scaledCIImage = ciimage.transformed(by: transform)
	let uiimage = UIImage(ciImage: scaledCIImage)
	return uiimage.pngData()!
}

struct SettingsView: View {
	@StateObject private var dataManager = DataManager()
	@State private var showingAddRecipient = false
	@State private var showingRenameRecipient = false
	@State private var newRecipientName = ""
	@State private var recipientToDelete: Recipient?
	@State private var showingDeleteAlert = false
	@State private var recipientToRename: Recipient?
	@State private var newName = ""

	var body: some View {
		NavigationStack {
			List {
				Section("Recipients") {
					ForEach(dataManager.recipients) { recipient in
						NavigationLink {
							RecipientDetailView(recipient: recipient)
						} label: {
							HStack {
								Text(recipient.name)
								Spacer()
								Text("^[\(dataManager.transactions.filter { transaction in transaction.splits.contains { $0.recipientId == recipient.id }}.count) transactions](inflect: true)")
									.foregroundStyle(.secondary)
							}
						}
						.swipeActions(edge: .trailing) {
							Button(role: .destructive) {
								recipientToDelete = recipient
								showingDeleteAlert = true
							} label: {
								Label("Delete", systemImage: "trash")
							}
						}
						.swipeActions(edge: .leading) {
							Button {
								recipientToRename = recipient
								newName = recipient.name
								showingRenameRecipient = true
							} label: {
								Label("Rename", systemImage: "pencil")
							}
							.tint(.blue)
						}
					}

					Button(action: {
						newRecipientName = ""
						showingAddRecipient = true
					}) {
						Label("New Recipient", systemImage: "plus")
					}
				}

				// Section("Family") {
				// 	NavigationLink {
				// 		VStack {
				// 			Image(uiImage: UIImage(data: getQRCodeDate(text: "Test")!)!)
				// 				.resizable()
				// 				.frame(width: 200, height: 200)
				// 		}

				// 	} label: {
				// 		Label {
				// 			VStack(alignment: .leading) {
				// 				Text("Show Pairing QR Code")
				// 					.font(.headline)
				// 				Text("Used to pair to a family.")
				// 					.font(.body)
				// 					.foregroundStyle(.secondary)
				// 			}
				// 		} icon: {
				// 			Image(systemName: "qrcode")
				// 				.foregroundStyle(Color.primary)
				// 		}
				// 	}
				// 	NavigationLink {
				// 		Text("Family")
				// 	} label: {
				// 		Label {
				// 			Text("Manage Family")
				// 		} icon: {
				// 			Image(systemName: "person.2.fill")
				// 				.foregroundStyle(Color.primary)
				// 		}
				// 	}
				// }

				Section("About this app") {
					HStack {
						Text("App Version")
						Spacer()
						Text("1.0")
							.foregroundStyle(.secondary)
							.textSelection(.enabled)
					}
				}
			}
			.navigationTitle("Settings")
			.refreshable {
				dataManager.loadRecipients()
				dataManager.loadTransactions()
				dataManager.objectWillChange.send()
			}
			.confirmationDialog(
				"Delete Recipient",
				isPresented: $showingDeleteAlert,
				presenting: recipientToDelete
			) { recipient in
				Button("Delete", role: .destructive) {
					if let index = dataManager.recipients.firstIndex(where: { $0.id == recipient.id }) {
						dataManager.deleteRecipient(at: IndexSet(integer: index))
						dataManager.objectWillChange.send()
					}
				}
			} message: { recipient in
				Text("Are you sure you want to delete '\(recipient.name)'? This action cannot be undone.")
			}
			.alert("Add Recipient", isPresented: $showingAddRecipient) {
				TextField("Name", text: $newRecipientName)
				Button("Cancel", role: .cancel) {
					newRecipientName = ""
				}
				Button("Add") {
					let recipient = Recipient(
						id: UUID(),
						name: newRecipientName,
						dateAdded: Date()
					)
					dataManager.addRecipient(recipient)
					dataManager.objectWillChange.send()
					newRecipientName = ""
				}
				.disabled(newRecipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}
			.alert("Rename Recipient", isPresented: $showingRenameRecipient, presenting: recipientToRename) { recipient in
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
		}
	}
}

#Preview {
	SettingsView()
}
