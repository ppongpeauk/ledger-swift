//
//  HomeView.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import SwiftUI

struct HomeView: View {
	@Binding var addSheetShown: Bool
	@StateObject private var dataManager = DataManager()
	@State private var transactionToDelete: Transaction?
	@State private var transactionToRename: Transaction?
	@State private var showingDeleteTransaction: Bool = false
	@State private var showingRenameTransaction: Bool = false
	@State private var newName = ""

	var body: some View {
		NavigationStack {
			List {
				Section {
					Button(action: {
						addSheetShown = true
					}) {
						Label("New Transaction", systemImage: "plus")
					}
				}
				Section {
					if !dataManager.transactions.isEmpty {
						ForEach(dataManager.transactions) { transaction in
							TransactionButton(transaction: transaction)
								.swipeActions {
									Button(role: .destructive) {
										transactionToDelete = transaction
										showingDeleteTransaction = true
									} label: {
										Label("Delete", systemImage: "trash")
									}
								}
								.swipeActions(edge: .leading) {
									Button {
										transactionToRename = transaction
										newName = transaction.name
										showingRenameTransaction = true
									} label: {
										Label("Rename", systemImage: "pencil")
									}
									.tint(.blue)
								}
						}
					} else {
						Text("No transactions yet.")
							.foregroundStyle(.secondary)
					}
				}
			}
			.navigationTitle("Ledger")
			.refreshable {
				dataManager.loadTransactions()
				dataManager.loadRecipients()
				dataManager.objectWillChange.send()
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: {
						addSheetShown = true
					}) {
						Image(systemName: "plus")
					}
				}
			}
			.sheet(isPresented: $addSheetShown) {
				AddSheetView(
					addSheetShown: $addSheetShown,
					dataManager: dataManager
				)
			}
			.alert("Rename Transaction", isPresented: $showingRenameTransaction, presenting: transactionToRename) { transaction in
				TextField("Name", text: $newName)
				Button("Cancel", role: .cancel) {
					newName = ""
				}
				Button("Save") {
					if let index = dataManager.transactions.firstIndex(where: { $0.id == transaction.id }) {
						var updatedTransaction = transaction
						updatedTransaction.name = newName
						dataManager.transactions[index] = updatedTransaction
						dataManager.saveTransactions()
						dataManager.objectWillChange.send()
					}
					newName = ""
				}
				.disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}
			.confirmationDialog(
				"Delete Transaction",
				isPresented: $showingDeleteTransaction,
				presenting: transactionToDelete
			) { transaction in
				Button("Delete \(transaction.name)", role: .destructive) {
					if let index = dataManager.transactions.firstIndex(where: { $0.id == transaction.id }) {
						dataManager.deleteTransaction(at: IndexSet(integer: index))
					}
				}
			} message: { transaction in
				Text("Are you sure you want to delete '\(transaction.name)'? This action cannot be undone.")
			}
		}
		.environment(\.dataManager, dataManager)
	}
}

#Preview {
	@Previewable @State var addSheetShown = false
	HomeView(addSheetShown: $addSheetShown)
}
