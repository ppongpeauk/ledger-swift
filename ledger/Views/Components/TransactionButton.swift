import SwiftUI

struct TransactionButton: View {
	@Environment(\.dataManager) private var dataManager
	let transaction: Transaction

	var body: some View {
		NavigationLink(destination: TransactionDetailView(transaction: transaction)
			.environment(\.dataManager, dataManager)
		) {
			VStack(alignment: .leading) {
				Text(transaction.name)
					.font(.headline)
				HStack(spacing: 4) {
					Text("$\(transaction.splits.reduce(0) { $0 + $1.price }, specifier: "%.2f")")
					Text("•")
					Text("^[\(transaction.splits.count) splits](inflect: true)")
				}
					.foregroundStyle(.secondary)
			}
		}
	}
}
