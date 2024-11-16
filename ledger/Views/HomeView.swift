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
	@State private var showingDeleteAlert = false

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
										showingDeleteAlert = true
									} label: {
										Label("Delete", systemImage: "trash")
									}
								}
						}
					} else {
						Text("No transactions yet.")
					}
				}
			}
			.navigationTitle("Ledger")
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
				AddSheetView(addSheetShown: $addSheetShown, dataManager: dataManager)
			}
			.confirmationDialog(
				"Delete Transaction",
				isPresented: $showingDeleteAlert,
				presenting: transactionToDelete
			) { transaction in
				Button("Delete \(transaction.name)", role: .destructive) {
					if let index = dataManager.transactions.firstIndex(where: { $0.id == transaction.id }) {
						dataManager.deleteTransaction(at: IndexSet(integer: index))
					}
				}
			} message: { transaction in
				Text("Are you sure you want to delete '\(transaction.name)'?")
			}
		}
		.environment(\.dataManager, dataManager)
	}
}

#Preview {
	@Previewable @State var addSheetShown = false
	HomeView(addSheetShown: $addSheetShown)
}
