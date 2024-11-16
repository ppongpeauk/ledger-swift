//
//  SettingsView.swift
//  ledger
//
//  Created by Pete Pongpeauk on 11/16/24.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

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
	var body: some View {
		NavigationStack {
			List {
				Section("Family") {
					NavigationLink {
						VStack {
							Image(uiImage: UIImage(data: getQRCodeDate(text: "Test")!)!)
								.resizable()
								.frame(width: 200, height: 200)
						}

					} label: {
						Label {
							VStack(alignment: .leading) {
								Text("Show Pairing QR Code")
									.font(.headline)
								Text("Used to pair to a family.")
									.font(.body)
									.foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "qrcode")
								.foregroundStyle(Color.primary)
						}
					}
					NavigationLink {
						Text("Family")
					} label: {
						Label {
							Text("Manage Family")
						} icon: {
							Image(systemName: "person.2.fill")
								.foregroundStyle(Color.primary)
						}
					}
				}

				Section("About this app") {
					NavigationLink {
						Text("hi")
					} label: {
						Text("Acknowledgements")
					}
					HStack {
						Text("App Version")
						Spacer()
						Text("1.1")
							.foregroundStyle(.secondary)
							.textSelection(.enabled)
					}
				}
			}
			.navigationTitle("Settings")
		}
	}
}

#Preview {
	SettingsView()
}
