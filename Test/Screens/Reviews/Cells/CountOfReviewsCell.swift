//
//  CountOfReviewsCell.swift
//  Test
//
//  Created by Dmitry Dorodniy on 02.03.2025.
//

import UIKit

final class CountOfReviewsCell: UITableViewCell {
    
    static let reuseId = String(describing: CountOfReviewsCell.self)

    fileprivate let countLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)  
        setupUI()
    }

     required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
      
    // MARK: - Layput
    private func setupUI() {
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.contentMode = .center
        countLabel.textAlignment = .center

        contentView.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    // MARK: - Config
    func configure(with count: Int) {
        countLabel.attributedText = "\(count) отзывов".attributed(font: .reviewCount)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        countLabel.attributedText = nil
    }
}
