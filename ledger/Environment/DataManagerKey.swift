import SwiftUI

private struct DataManagerKey: EnvironmentKey {
    static let defaultValue = DataManager()
}

extension EnvironmentValues {
    var dataManager: DataManager {
        get { self[DataManagerKey.self] }
        set { self[DataManagerKey.self] = newValue }
    }
} 