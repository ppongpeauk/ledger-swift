//
//  Category.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import Foundation
import SwiftData

@Model
class Category: Hashable, Identifiable {
	var id = UUID()
	var name: String
	var about: String?
	var icon: Icon
	var authorId: User.ID

	init(
		id: UUID = UUID(),
		name: String,
		about: String? = nil,
		icon: Icon,
		authorId: User.ID
	) {
		self.id = id
		self.name = name
		self.about = about
		self.icon = icon
		self.authorId = authorId
	}
}
