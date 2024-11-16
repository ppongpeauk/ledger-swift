//
//  Main.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import SwiftUI

struct MainView: View {
	@State private var addSheetVisible: Bool = false

	var body: some View {
		TabView {
			// Home Tab
			HomeView(addSheetShown: $addSheetVisible)
				.tabItem {
					Label("Home", systemImage: "house")
				}
				.tag(0)

			// Settings Tab
			SettingsView()
				.tabItem {
					Label("Settings", systemImage: "gear")
				}
				.tag(1)
		}
	}
}

#Preview {
	MainView()
}
