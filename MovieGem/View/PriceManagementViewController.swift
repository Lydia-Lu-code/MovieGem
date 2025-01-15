//
//  PriceManagementViewController.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import UIKit
import Combine

class PriceManagementViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: PriceManagementViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["基本票價", "折扣方案"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(PriceTableViewCell.self, forCellReuseIdentifier: "PriceCell")
        table.register(DiscountTableViewCell.self, forCellReuseIdentifier: "DiscountCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("新增", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    init(viewModel: PriceManagementViewModel = PriceManagementViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = PriceManagementViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.loadData()
        
        view.backgroundColor = .white
        title = "票價設定"
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "票價管理"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshData)
        )
        
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(addButton)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // 監聽載入狀態
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.tableView.alpha = 0.5
                    self?.tableView.isUserInteractionEnabled = false
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.tableView.alpha = 1
                    self?.tableView.isUserInteractionEnabled = true
                }
            }
            .store(in: &cancellables)
        
        // 監聽錯誤
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
        
        // 監聽資料更新
        Publishers.CombineLatest(viewModel.$prices, viewModel.$discounts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // 監聽分段控制
        viewModel.$selectedSegmentIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.segmentedControl.selectedSegmentIndex = index
                self?.addButton.setTitle(index == 0 ? "新增票價" : "新增折扣", for: .normal)
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        viewModel.selectedSegmentIndex = sender.selectedSegmentIndex
    }
    
    @objc private func refreshData() {
        viewModel.loadData()
    }
    
    @objc private func addTapped() {
        if viewModel.selectedSegmentIndex == 0 {
            showAddPriceAlert()
        } else {
            showAddDiscountAlert()
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            guard let basePrice = Double(alert.textFields?[0].text ?? ""),
                  let holidayPrice = Double(alert.textFields?[1].text ?? "") else {
                return
            }
            
            let newPrice = ShowtimePrice(
                basePrice: basePrice,
                weekendPrice: holidayPrice,
                holidayPrice: holidayPrice,
                studentPrice: basePrice * 0.8,
                seniorPrice: basePrice * 0.5,
                childPrice: basePrice * 0.5,
                vipPrice: basePrice * 1.5,
                discounts: []
            )
            
            Task {
                do {
                    try await self?.viewModel.addPrice(newPrice)
                } catch {
                    self?.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showAddDiscountAlert() {
        let alert = UIAlertController(title: "新增折扣", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "折扣名稱"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "折扣值"
            textField.keyboardType = .decimalPad
        }
        
        let pickerVC = UIAlertController(title: "選擇折扣類型", message: nil, preferredStyle: .actionSheet)
        [PriceDiscount.DiscountType.percentage, .fixedAmount].forEach { type in
            let action = UIAlertAction(title: type.rawValue, style: .default) { [weak self] _ in
                guard let name = alert.textFields?[0].text,
                      let valueText = alert.textFields?[1].text,
                      let value = Double(valueText) else {
                    return
                }
                
                let newDiscount = PriceDiscount(
                    id: UUID().uuidString,
                    name: name,
                    type: type,
                    value: value,
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(86400 * 30),
                    description: "新增折扣方案"
                )
                
                Task {
                    do {
                        try await self?.viewModel.addDiscount(newDiscount)
                    } catch {
                        self?.showError(error)
                    }
                }
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
    
    //  在 PriceManagementViewController 中添加 showAddPriceAlert 方法
    private func showAddPriceAlert() {
        let alert = UIAlertController(title: "新增票價", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "基本票價"
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "假日票價"
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "學生票價"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            guard let basePrice = Double(alert.textFields?[0].text ?? ""),
                  let weekendPrice = Double(alert.textFields?[1].text ?? ""),
                  let studentPrice = Double(alert.textFields?[2].text ?? "") else {
                return
            }
            
            let newPrice = ShowtimePrice(
                basePrice: basePrice,
                weekendPrice: weekendPrice,
                holidayPrice: weekendPrice,
                studentPrice: studentPrice,
                seniorPrice: basePrice * 0.5,
                childPrice: basePrice * 0.5,
                vipPrice: basePrice * 1.5,
                discounts: []  // 添加空的折扣陣列
            )
            
            Task {
                do {
                    try await self?.viewModel.addPrice(newPrice)
                } catch {
                    self?.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
}

// MARK: - UITableViewDataSource & Delegate
extension PriceManagementViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.selectedSegmentIndex == 0 ? viewModel.prices.count : viewModel.discounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.selectedSegmentIndex == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PriceCell", for: indexPath) as? PriceTableViewCell else {
                return UITableViewCell()
            }
            let price = viewModel.prices[indexPath.row]
            cell.configure(with: price)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DiscountCell", for: indexPath) as? DiscountTableViewCell else {
                return UITableViewCell()
            }
            let discount = viewModel.discounts[indexPath.row]
            cell.configure(with: discount)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if viewModel.selectedSegmentIndex == 0 {
            let price = viewModel.prices[indexPath.row]
            showEditPriceAlert(price)
        } else {
            let discount = viewModel.discounts[indexPath.row]
            showEditDiscountAlert(discount)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .destructive, title: "刪除") { [weak self] _, _, completion in
            Task {
                do {
                    if self?.viewModel.selectedSegmentIndex == 0 {
                        try await self?.viewModel.deletePrice(at: indexPath.row)
                    } else {
                        try await self?.viewModel.deleteDiscount(at: indexPath.row)
                    }
                    completion(true)
                } catch {
                    self?.showError(error)
                    completion(false)
                }
            }
        }
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    private func showEditPriceAlert(_ price: ShowtimePrice) {
        let alert = UIAlertController(title: "編輯票價", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "基本票價"
            textField.text = "\(price.basePrice)"
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "假日票價"
            textField.text = "\(price.weekendPrice ?? price.basePrice)"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            guard let basePrice = Double(alert.textFields?[0].text ?? ""),
                  let weekendPrice = Double(alert.textFields?[1].text ?? "") else {
                return
            }
            
            var updatedPrice = price
            updatedPrice.basePrice = basePrice
            updatedPrice.weekendPrice = weekendPrice
            updatedPrice.holidayPrice = weekendPrice
            
            Task {
                do {
                    try await self?.viewModel.updatePrice(updatedPrice)
                } catch {
                    self?.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showEditDiscountAlert(_ discount: PriceDiscount) {
        let alert = UIAlertController(title: "編輯折扣", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "折扣名稱"
            textField.text = discount.name
        }
        
        alert.addTextField { textField in
            textField.placeholder = "折扣值"
            textField.text = "\(discount.value)"
            textField.keyboardType = .decimalPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "折扣說明"
            textField.text = discount.description
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text,
                  let valueText = alert.textFields?[1].text,
                  let value = Double(valueText),
                  let description = alert.textFields?[2].text else {
                return
            }
            
            var updatedDiscount = discount
            updatedDiscount.name = name
            updatedDiscount.value = value
            updatedDiscount.description = description
            
            Task {
                do {
                    try await self?.viewModel.updateDiscount(updatedDiscount)
                } catch {
                    self?.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
}
