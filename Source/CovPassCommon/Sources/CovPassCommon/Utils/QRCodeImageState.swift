//
//  File.swift
//  
//
//  Created by Alexander Korus on 17.12.21.
//

import Foundation
public class QRCodeImageState {

	public static let `default`: QRCodeImageState = {
		QRCodeImageState()
	}()

	public var qrCodeData: String? = nil

	private init() {}
}
