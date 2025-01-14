//
//  MovieTicketCell.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import UIKit

class MovieTicketCell: UITableViewCell {
    static let identifier = "MovieTicketCell"
    
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let movieNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let dateTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    private let seatsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(stackView)
        
        stackView.addArrangedSubview(movieNameLabel)
        stackView.addArrangedSubview(dateTimeLabel)
        stackView.addArrangedSubview(seatsLabel)
        stackView.addArrangedSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with movie: MovieSheetData) {
        print("🟣 開始配置 Cell: \(movie.movieName)")
        
        // 避免重複配置，先檢查是否已經有相同的內容
        if movieNameLabel.text == "🎬 \(movie.movieName)" {
            print("🟣 跳過重複配置: \(movie.movieName)")
            return
        }
        
        movieNameLabel.text = "🎬 \(movie.movieName)"
        dateTimeLabel.text = "📅 \(movie.showDate) \(movie.showTime)"
        seatsLabel.text = "💺 座位：\(movie.seats) (\(movie.ticketType))"
        amountLabel.text = "💰 NT$ \(movie.totalAmount)"
        
        print("🟣 完成配置 Cell: \(movie.movieName)")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        print("🟣 準備重用 Cell")
        movieNameLabel.text = nil
        dateTimeLabel.text = nil
        seatsLabel.text = nil
        amountLabel.text = nil
    }

    
}


