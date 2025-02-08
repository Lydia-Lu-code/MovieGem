//
//  DiscountTableViewCell.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import UIKit

class DiscountTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(infoStackView)
        containerStackView.addArrangedSubview(statusLabel)
        
        infoStackView.addArrangedSubview(nameLabel)
        infoStackView.addArrangedSubview(detailsLabel)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }
    
    func configure(with discount: PriceDiscount) {
        nameLabel.text = discount.name
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateRange = "\(formatter.string(from: discount.startDate)) - \(formatter.string(from: discount.endDate))"
        
        let valueText: String
        switch discount.type {
        case .percentage:
            valueText = String(format: "%.0f折", discount.value * 10)
            statusLabel.backgroundColor = .systemGreen.withAlphaComponent(0.2)
            statusLabel.textColor = .systemGreen
        case .fixedAmount:
            valueText = "減\(Int(discount.value))元"
            statusLabel.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            statusLabel.textColor = .systemBlue
        }
        
        detailsLabel.text = "\(valueText) | \(dateRange)"
        statusLabel.text = discount.type.rawValue
    }
}

