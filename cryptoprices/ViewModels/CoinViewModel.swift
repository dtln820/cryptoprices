//
//  CoinViewModel.swift
//  cryptoprices
//
//  Created by SDE3 on 7/28/22.
//

import Foundation

class CoinViewModel {
	private let model: CoinEntity
	// May consider making it static
	private let numberFormatter: NumberFormatter

	init(model: CoinEntity) {
		self.model = model
		self.numberFormatter = NumberFormatter()
		self.numberFormatter.groupingSeparator = ","
		self.numberFormatter.groupingSize = 3
		self.numberFormatter.usesGroupingSeparator = true
		self.numberFormatter.decimalSeparator = "."
		self.numberFormatter.numberStyle = .decimal
		self.numberFormatter.maximumFractionDigits = 6
	}

	var symbol: String {
		return model.symbol
	}

	var name: String {
		return model.name
	}

	var iconUrl: URL? {
		guard let iconUrlAsString = model.iconUrl else { return nil }
		return URL(string: iconUrlAsString)
	}

	var currentPrice: String {
		if model.currentPrice > 1 {
			self.numberFormatter.maximumFractionDigits = 2
		} else {
			self.numberFormatter.maximumFractionDigits = 6
		}
		return "$ \(numberFormatter.string(from: model.currentPrice as NSNumber)!)"
	}

	var minPrice: String {
		if model.minPrice > 1 {
			self.numberFormatter.maximumFractionDigits = 2
		} else {
			self.numberFormatter.maximumFractionDigits = 6
		}
		return "$ \(numberFormatter.string(from: model.minPrice as NSNumber)!)"
	}

	var maxPrice: String {
		if model.maxPrice > 1 {
			self.numberFormatter.maximumFractionDigits = 2
		} else {
			self.numberFormatter.maximumFractionDigits = 6
		}
		return "$ \(numberFormatter.string(from: model.maxPrice as NSNumber)!)"
	}
}
