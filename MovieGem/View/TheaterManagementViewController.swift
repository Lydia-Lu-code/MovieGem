//
//  TheaterManagementViewController.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import UIKit

class TheaterManagementViewController: UIViewController {
    // MARK: - Properties
    private var theaters: [Theater] = []
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TheaterCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("新增影廳", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addTheaterTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTheaters()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "影廳管理"
        
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Data Loading
    private func loadTheaters() {
        // 模擬數據載入
        theaters = [
            Theater(id: "1", name: "第一影廳", capacity: 120, type: .standard,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
            Theater(id: "2", name: "IMAX影廳", capacity: 180, type: .imax,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12)),
            Theater(id: "3", name: "VIP影廳", capacity: 60, type: .vip,
                   status: .maintenance, seatLayout: Array(repeating: Array(repeating: .vip, count: 8), count: 8))
        ]
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func addTheaterTapped() {
        let alert = UIAlertController(title: "新增影廳", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "影廳名稱"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "座位容量"
            textField.keyboardType = .numberPad
        }
        
        let pickerVC = UIAlertController(title: "選擇影廳類型", message: nil, preferredStyle: .actionSheet)
        Theater.TheaterType.allCases.forEach { type in
            let action = UIAlertAction(title: type.rawValue, style: .default) { [weak self] _ in
                guard let name = alert.textFields?[0].text,
                      let capacityText = alert.textFields?[1].text,
                      let capacity = Int(capacityText) else { return }
                
                let newTheater = Theater(
                    id: UUID().uuidString,
                    name: name,
                    capacity: capacity,
                    type: type,
                    status: .active,
                    seatLayout: Array(repeating: Array(repeating: .normal, count: Int(sqrt(Double(capacity)))),
                                    count: Int(sqrt(Double(capacity))))
                )
                
                self?.theaters.append(newTheater)
                self?.tableView.reloadData()
            }
            pickerVC.addAction(action)
        }
        
        pickerVC.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "下一步", style: .default) { [weak self] _ in
            self?.present(pickerVC, animated: true)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showTheaterDetails(_ theater: Theater) {
        // 創建 GoogleSheetsService 實例
        let sheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)
        
        // 使用 sheetsService 創建 ViewModel 實例
        let movieSheetViewModel = MovieSheetViewModel(sheetsService: sheetsService)
        
        // 使用 ViewModel 實例創建 ViewController
        let detailVC = TheaterDetailViewController(theater: theater, viewModel: movieSheetViewModel)
        
        navigationController?.pushViewController(detailVC, animated: true)
    }

}

// MARK: - UITableViewDataSource & Delegate
extension TheaterManagementViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return theaters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TheaterCell", for: indexPath)
        let theater = theaters[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = "\(theater.name) (\(theater.type.rawValue))"
        config.secondaryText = "座位數: \(theater.capacity) | 狀態: \(theater.status.rawValue)"
        cell.contentConfiguration = config
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let theater = theaters[indexPath.row]
        showTheaterDetails(theater)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        
        let theater = theaters[indexPath.row]
        
        let delete = UIContextualAction(style: .destructive, title: "刪除") { [weak self] _, _, completion in
            self?.theaters.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        
        let status = UIContextualAction(style: .normal, title: "狀態") { [weak self] _, _, completion in
            let alert = UIAlertController(title: "更改狀態", message: nil, preferredStyle: .actionSheet)
            
            Theater.TheaterStatus.allCases.forEach { status in
                let action = UIAlertAction(title: status.rawValue, style: .default) { _ in
                    var updatedTheater = theater
                    updatedTheater.status = status
                    self?.theaters[indexPath.row] = updatedTheater
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                alert.addAction(action)
            }
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            self?.present(alert, animated: true)
            completion(true)
        }
        
        status.backgroundColor = UIColor.systemBlue
        
        return UISwipeActionsConfiguration(actions: [delete, status])
    }
}
