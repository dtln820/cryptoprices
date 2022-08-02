//
//  CoinCell.swift
//  cryptoprices
//
//  Created by SDE3 on 7/28/22.
//

import UIKit
import SnapKit

class CoinCell: UITableViewCell {

	var coinIconImageView: UIImageView!
	var coinNameLabel: UILabel!
	var coinSymbolLabel: UILabel!
	var coinCurrentPriceContainer: UIView!
	var coinCurrentPriceLabel: UILabel!
	var coinMinPriceLabel: UILabel!
	var coinMaxPriceLabel: UILabel!

	private var task: URLSessionDataTask?
	private var currentPrice: Double?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .default, reuseIdentifier: reuseIdentifier)

		build()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func build() {
		coinIconImageView = UIImageView()
		contentView.addSubview(coinIconImageView)
		coinIconImageView.snp.makeConstraints {
			$0.width.height.equalTo(32)
			$0.left.equalToSuperview()
			$0.top.equalToSuperview().offset(12)
		}

		coinNameLabel = UILabel()
		coinNameLabel.font = .systemFont(ofSize: 16, weight: .regular)
		contentView.addSubview(coinNameLabel)
		coinNameLabel.snp.makeConstraints {
			$0.top.greaterThanOrEqualToSuperview()
			$0.bottom.lessThanOrEqualToSuperview()
			$0.centerY.equalTo(coinIconImageView.snp.centerY)
			$0.left.equalTo(coinIconImageView.snp.right).offset(8)
		}

		coinSymbolLabel = UILabel()
		coinSymbolLabel.font = .systemFont(ofSize: 16, weight: .regular)
		coinSymbolLabel.textColor = .lightGray
		contentView.addSubview(coinSymbolLabel)
		coinSymbolLabel.snp.makeConstraints {
			$0.centerY.equalTo(coinIconImageView.snp.centerY)
			$0.left.equalTo(coinNameLabel.snp.right).offset(8)
		}

		coinCurrentPriceLabel = UILabel()
		coinCurrentPriceLabel.font = .systemFont(ofSize: 16, weight: .regular)

		coinCurrentPriceContainer = UIView()
		coinCurrentPriceContainer.layer.cornerRadius = 6
		coinCurrentPriceContainer.addSubview(coinCurrentPriceLabel)
		coinCurrentPriceLabel.snp.makeConstraints {
			$0.left.equalToSuperview().offset(4)
			$0.right.equalToSuperview().offset(-4)
			$0.top.equalToSuperview().offset(8)
			$0.bottom.equalToSuperview().offset(-8)
		}

		contentView.addSubview(coinCurrentPriceContainer)
		coinCurrentPriceContainer.snp.makeConstraints {
			$0.top.greaterThanOrEqualToSuperview()
			$0.bottom.lessThanOrEqualToSuperview()
			$0.right.equalToSuperview()
			$0.centerY.equalTo(coinIconImageView.snp.centerY)
			$0.width.greaterThanOrEqualTo(64)
		}

		coinMinPriceLabel = UILabel()
		coinMinPriceLabel.font = .systemFont(ofSize: 12, weight: .regular)
		contentView.addSubview(coinMinPriceLabel)
		coinMinPriceLabel.snp.makeConstraints {
			$0.left.equalTo(coinNameLabel.snp.left)
			$0.top.equalTo(coinNameLabel.snp.bottom).offset(12)
			$0.bottom.equalToSuperview().offset(-4)
		}

		coinMaxPriceLabel = UILabel()
		coinMaxPriceLabel.font = .systemFont(ofSize: 12, weight: .regular)
		contentView.addSubview(coinMaxPriceLabel)
		coinMaxPriceLabel.snp.makeConstraints {
			$0.left.equalTo(coinMinPriceLabel.snp.right).offset(12)
			$0.top.equalTo(coinNameLabel.snp.bottom).offset(12)
			$0.bottom.equalToSuperview().offset(-4)
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		task?.cancel()
		self.coinIconImageView.image = nil
	}

	func updateCell(with coinViewModel: CoinViewModel) {
		coinNameLabel.text = coinViewModel.name
		coinSymbolLabel.text = coinViewModel.symbol

		coinCurrentPriceLabel.text = coinViewModel.currentPriceAsString

		if let safeCurrentPrice = currentPrice {
			if coinViewModel.currentPrice > safeCurrentPrice {
				UIView.animate(withDuration: 0.5, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
					self?.coinCurrentPriceContainer.backgroundColor = .systemGreen
				}, completion: { [weak self] finished in
					if finished {
						UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
							self?.coinCurrentPriceContainer.backgroundColor = .white
						}, completion: nil)
					}
				})
			} else if coinViewModel.currentPrice < safeCurrentPrice {
				UIView.animate(withDuration: 0.5, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
					self?.coinCurrentPriceContainer.backgroundColor = .systemRed
				}, completion: { [weak self] finished in
					if finished {
						UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
							self?.coinCurrentPriceContainer.backgroundColor = .white
						}, completion: nil)
					}
				})
			}
		}

		let minPriceAttributedString = NSMutableAttributedString(string: "min: \(coinViewModel.minPriceAsString)", attributes: nil)
		let minTextRange = ("min: \(coinViewModel.minPriceAsString)" as NSString).range(of: "min:")
		minPriceAttributedString.addAttribute(.foregroundColor, value: UIColor.lightGray, range: minTextRange)
		coinMinPriceLabel.attributedText = minPriceAttributedString

		let maxPriceAttributedString = NSMutableAttributedString(string: "max: \(coinViewModel.maxPriceAsString)", attributes: nil)
		let maxTextRange = ("max: \(coinViewModel.maxPriceAsString)" as NSString).range(of: "max:")
		maxPriceAttributedString.addAttribute(.foregroundColor, value: UIColor.lightGray, range: maxTextRange)
		coinMaxPriceLabel.attributedText = maxPriceAttributedString

		if let url = coinViewModel.iconUrl {
			task = URLSession.shared.dataTask(with: url) { data, response, error in
				guard let data = data, error == nil else { return }

				DispatchQueue.main.async { [weak self] in
					self?.coinIconImageView.image = UIImage(data: data)
				}
			}

			task?.resume()
		}

		self.currentPrice = coinViewModel.currentPrice
	}
}
