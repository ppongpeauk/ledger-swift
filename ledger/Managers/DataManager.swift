import Foundation

class DataManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private let transactionsKey = "saved_transactions"
    
    init() {
        loadTransactions()
    }
    
    func loadTransactions() {
        if let data = UserDefaults.standard.data(forKey: transactionsKey) {
            if let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
                transactions = decoded
                return
            }
        }
        transactions = []
    }
    
    func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
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
} 