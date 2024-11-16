//
//  User.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import Foundation
import SwiftData

@Model
class User: Hashable, Identifiable {
	var id = UUID()
	var username: String

	init(id: UUID = UUID(), username: String) {
		self.id = id
		self.username = username
	}
}
