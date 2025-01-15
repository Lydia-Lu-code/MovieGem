//
//  ShowtimeTableViewCell.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import UIKit

class ShowtimeTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        return label
    }()
    
    private let theaterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGray
        return label
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemBlue
        return label
    }()
    
    private let seatsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGray
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
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
        contentView.addSubview(containerView)
        containerView.addSubview(stackView)
        
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(theaterLabel)
        stackView.addArrangedSubview(infoStackView)
        stackView.addArrangedSubview(statusLabel)
        
        infoStackView.addArrangedSubview(priceLabel)
        infoStackView.addArrangedSubview(seatsLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with showtime: MovieShowtime) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startTimeStr = formatter.string(from: showtime.startTime)
        let endTimeStr = formatter.string(from: showtime.endTime)
        
        timeLabel.text = "\(startTimeStr) - \(endTimeStr)"
        theaterLabel.text = "影廳：第\(showtime.theaterId)廳"
        priceLabel.text = "💰 NT$ \(Int(showtime.price.basePrice))"
        seatsLabel.text = "💺 剩餘 \(showtime.availableSeats)"
        
        // 設置狀態標籤的樣式
        statusLabel.text = showtime.status.rawValue
        switch showtime.status {
        case .scheduled:
            statusLabel.backgroundColor = .systemGray6
            statusLabel.textColor = .systemGray
        case .onSale:
            statusLabel.backgroundColor = .systemGreen.withAlphaComponent(0.2)
            statusLabel.textColor = .systemGreen
        case .almostFull:
            statusLabel.backgroundColor = .systemOrange.withAlphaComponent(0.2)
            statusLabel.textColor = .systemOrange
        case .soldOut:
            statusLabel.backgroundColor = .systemRed.withAlphaComponent(0.2)
            statusLabel.textColor = .systemRed
        case .canceled:
            statusLabel.backgroundColor = .systemGray.withAlphaComponent(0.2)
            statusLabel.textColor = .systemGray
        }
    }
}
