//
//  CoinPricesViewController.swift
//  cryptoprices
//
//  Created by SDE3 on 7/28/22.
//

import UIKit
import SnapKit
import CryptoAPI
import RealmSwift

class CoinPricesViewController: UIViewController {

	private var titleLabel: UILabel!
	private var pricesTableView: UITableView!
	private let localRealm = try! Realm()
	private var cryptoAPI: Crypto!
	var notificationToken: NotificationToken?

	private lazy var coinsResults: Results<CoinEntity> = {
		return localRealm.objects(CoinEntity.self)
	}()

	override func viewDidLoad() {
		super.viewDidLoad()

		createViewsAndSetConstraints()
		cryptoAPI = Crypto(delegate: self)
		connectCryptoAPI()
		fetchCoinsData()

		notificationToken = coinsResults.observe { [weak self] (changes: RealmCollectionChange) in
			guard let `self` = self else { return }

			guard let tableView = self.pricesTableView else { return }
			switch changes {
			case .initial:
				// Results are now populated and can be accessed without blocking the UI
				tableView.reloadData()
			case .update(_, let deletions, let insertions, let modifications):
				// Query results have changed, so apply them to the UITableView
				tableView.performBatchUpdates({
					// Always apply updates in the following order: deletions, insertions, then modifications.
					// Handling insertions before deletions may result in unexpected behavior.
					tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
										 with: .automatic)
					tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
										 with: .automatic)
					tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
										 with: .none)
				})
			case .error(let error):
				// An error occurred while opening the Realm file on the background worker thread
				fatalError("\(error)")
			}
		}

		print("User Realm User file location: \(localRealm.configuration.fileURL!.path)")
	}

	func connectCryptoAPI() {
		let result = cryptoAPI.connect()
		switch result {
		case .success(let value):
			if value {
				print("successfully connected to crypto api")
			} else {
				print("did not connected to crypto api")
			}
		case .failure(let error):
			if let cryptoError = error as? CryptoError {
				switch cryptoError {
				case .connectAfter(let date):
					let diffSeconds = date.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
					DispatchQueue.main.asyncAfter(deadline: .now() + diffSeconds) { [weak self] in
						guard let `self` = self else { return }
						self.connectCryptoAPI()
					}
				@unknown default:
					print("Some unknown error occured")
				}
			}
			print("Failed to connect to crypto API with error: \(error.localizedDescription)")
		}
	}

	func fetchCoinsData() {
		let coins = cryptoAPI.getAllCoins()

		coins.forEach { fetchedCoin in
			try! localRealm.write {
				if let localCoin = localRealm.object(ofType: CoinEntity.self, forPrimaryKey: fetchedCoin.code) {
					localCoin.name = fetchedCoin.name
					localCoin.iconUrl = fetchedCoin.imageUrl
					localCoin.currentPrice = fetchedCoin.price

					if localCoin.minPrice > fetchedCoin.price {
						localCoin.minPrice = fetchedCoin.price
					} else if localCoin.maxPrice < fetchedCoin.price {
						localCoin.maxPrice = fetchedCoin.price
					}
				} else {
					localRealm.add(CoinEntity(from: fetchedCoin))
				}
			}
		}
	}

	func createViewsAndSetConstraints() {
		view.backgroundColor = .white

		var topPadding: CGFloat = 0
		if #available(iOS 13.0, *) {
			let window = UIApplication.shared.windows.first
			topPadding = window?.safeAreaInsets.top ?? 0
		}

		titleLabel = UILabel()
		titleLabel.text = "Market"
		titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
		view.addSubview(titleLabel)
		titleLabel.snp.makeConstraints {
			$0.top.equalToSuperview().offset(topPadding + 8)
			$0.left.equalToSuperview().offset(24)
			$0.right.equalToSuperview()
		}

		pricesTableView = UITableView()
		view.addSubview(pricesTableView)
		pricesTableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

		pricesTableView.dataSource = self
//		let dataSource = UITableViewDiffableDataSource<Int, CoinEntity>(tableView: pricesTableView) { (tableView, indexPath, coinEntity) -> UITableViewCell? in
//			let cell = tableView.dequeueReusableCell(withIdentifier: "coinCell", for: indexPath) as! CoinCell
//			let coinViewModel = CoinViewModel(model: coinEntity)
//			cell.tag = indexPath.row
//			cell.updateCell(with: coinViewModel, indexPathRow: indexPath.row)
//
//			return cell
//		}
//		pricesTableView.dataSource = dataSource
		pricesTableView.register(CoinCell.self, forCellReuseIdentifier: "coinCell")
		pricesTableView.tableFooterView = UIView()
		pricesTableView.snp.makeConstraints {
			$0.top.equalTo(titleLabel.snp.bottom).offset(24)
			$0.left.equalToSuperview().offset(24)
			$0.right.equalToSuperview().offset(-18)
			$0.bottom.equalToSuperview()
		}
	}
}

extension CoinPricesViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		coinsResults.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let coinForRow = coinsResults[indexPath.row]
		let coinViewModel = CoinViewModel(model: coinForRow)

		let cell = tableView.dequeueReusableCell(withIdentifier: "coinCell", for: indexPath) as! CoinCell
		cell.updateCell(with: coinViewModel)

		return cell
	}


}

extension CoinPricesViewController: CryptoDelegate {
	func cryptoAPIDidConnect() {
		print("connected")
	}

	func cryptoAPIDidUpdateCoin(_ coin: Coin) {
		print("coin updated: \(coin.name) with price \(coin.price)")
		DispatchQueue.main.async {
			try! self.localRealm.write {
				if let localCoin = self.localRealm.object(ofType: CoinEntity.self, forPrimaryKey: coin.code) {
					localCoin.name = coin.name
					localCoin.iconUrl = coin.imageUrl
					localCoin.currentPrice = coin.price

					if localCoin.minPrice > coin.price {
						localCoin.minPrice = coin.price
					} else if localCoin.maxPrice < coin.price {
						localCoin.maxPrice = coin.price
					}
				}
			}
		}
	}

	func cryptoAPIDidDisconnect() {
		print("disconnected")
		connectCryptoAPI()
	}


}
