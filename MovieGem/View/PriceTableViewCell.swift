//
//  PriceTableViewCell.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import UIKit

class PriceTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
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
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with price: ShowtimePrice) {
        titleLabel.text = "基本票價：NT$ \(Int(price.basePrice))"
        
        let weekendText = price.weekendPrice != nil ? "假日票價：NT$ \(Int(price.weekendPrice!))" : ""
        let studentText = price.studentPrice != nil ? "學生票價：NT$ \(Int(price.studentPrice!))" : ""
        
        subtitleLabel.text = [weekendText, studentText].filter { !$0.isEmpty }.joined(separator: " | ")
    }
}
