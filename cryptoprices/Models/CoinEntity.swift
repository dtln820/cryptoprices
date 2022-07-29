//
//  CoinEntity.swift
//  cryptoprices
//
//  Created by SDE3 on 7/28/22.
//

import Foundation
import RealmSwift
import CryptoAPI

class CoinEntity: Object {
	@Persisted(primaryKey: true) var symbol: String = ""
	@Persisted var name: String = ""
	@Persisted var currentPrice: Double = 0.0
	@Persisted var minPrice: Double = 0.0
	@Persisted var maxPrice: Double = 0.0
	@Persisted var iconUrl: String?

	convenience init(from coin: Coin) {
		self.init()
		self.symbol = coin.code
		self.name = coin.name
		self.currentPrice = coin.price
		self.minPrice = coin.price
		self.maxPrice = coin.price
		self.iconUrl = coin.imageUrl
	}
}
