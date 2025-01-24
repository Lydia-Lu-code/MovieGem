//
//  TheaterManagementViewController.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/16.
//

import UIKit
import Combine

class TheaterManagementViewController: UIViewController {
    // 公開 ViewModel，以便外部可以調用
    let viewModel: TheaterManagementViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TheaterCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    init(viewModel: TheaterManagementViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = TheaterManagementViewModel()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$theaters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// TableView DataSource & Delegate
extension TheaterManagementViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.theaters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TheaterCell", for: indexPath)
        let theater = viewModel.theaters[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = "\(theater.name) (\(theater.type.rawValue))"
        config.secondaryText = "座位數: \(theater.capacity) | 狀態: \(theater.status.rawValue)"
        cell.contentConfiguration = config
        
        return cell
    }
}

////
////  TheaterManagementViewController.swift
////  MovieGem
////
////  Created by Lydia Lu on 2025/1/16.
////
//
//import UIKit
//import Combine
//
//class TheaterManagementViewController: UIViewController {
//    // 公開 ViewModel，以便外部可以調用
//    let viewModel: TheaterManagementViewModel
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    private lazy var tableView: UITableView = {
//        let table = UITableView(frame: .zero, style: .insetGrouped)
//        table.delegate = self
//        table.dataSource = self
//        table.register(UITableViewCell.self, forCellReuseIdentifier: "TheaterCell")
//        table.translatesAutoresizingMaskIntoConstraints = false
//        return table
//    }()
//    
//    init(viewModel: TheaterManagementViewModel) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        self.viewModel = TheaterManagementViewModel()
//        super.init(coder: coder)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupBindings()
//        viewModel.loadData()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        view.addSubview(tableView)
//        
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: view.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    private func setupBindings() {
//        viewModel.$theaters
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.tableView.reloadData()
//            }
//            .store(in: &cancellables)
//    }
//}
//
//// TableView DataSource & Delegate
//extension TheaterManagementViewController: UITableViewDataSource, UITableViewDelegate {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.theaters.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "TheaterCell", for: indexPath)
//        let theater = viewModel.theaters[indexPath.row]
//        
//        var config = cell.defaultContentConfiguration()
//        config.text = "\(theater.name) (\(theater.type.rawValue))"
//        config.secondaryText = "座位數: \(theater.capacity) | 狀態: \(theater.status.rawValue)"
//        cell.contentConfiguration = config
//        
//        return cell
//    }
//}
