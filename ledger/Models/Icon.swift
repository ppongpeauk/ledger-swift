//
//  Icon.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import SwiftData

@Model
class Icon {
	var systemName: String

	init(systemName: String) {
		self.systemName = systemName
	}
}
