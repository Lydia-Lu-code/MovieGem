//
//  ShowtimeManagementViewController.swift
//  MovieGem
//
//  Created by Lydia Lu on 2025/1/14.
//

import UIKit

class ShowtimeManagementViewController: UIViewController {
    // MARK: - Properties
    private var showtimes: [MovieShowtime] = []
    private var filteredShowtimes: [MovieShowtime] = []
    private var selectedDate: Date = Date()
    private var theaters: [Theater] = []
    
    // MARK: - UI Components
    private lazy var calendarView: UICalendarView = {
        let calendar = UICalendarView()
        calendar.calendar = .current
        calendar.locale = .current
        calendar.delegate = self
        calendar.translatesAutoresizingMaskIntoConstraints = false
        
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        calendar.selectionBehavior = dateSelection
        return calendar
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["全部", "售票中", "即將額滿", "已售完", "已取消"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(ShowtimeTableViewCell.self, forCellReuseIdentifier: "ShowtimeCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("新增場次", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addShowtimeTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
        
        view.backgroundColor = .white
        title = "場次管理"
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "場次管理"
        
        // Add refresh button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshData)
        )
        
        view.addSubview(calendarView)
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            calendarView.heightAnchor.constraint(equalToConstant: 300),
            
            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
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
    private func loadInitialData() {
        // 載入影廳資料
        theaters = [
            Theater(id: "1", name: "第一廳", capacity: 120, type: .standard,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 12), count: 10)),
            Theater(id: "2", name: "IMAX廳", capacity: 180, type: .imax,
                   status: .active, seatLayout: Array(repeating: Array(repeating: .normal, count: 15), count: 12))
        ]
        
        // 模擬場次資料
        let showtimeData: [MovieShowtime] = [
            MovieShowtime(
                id: "1",
                movieId: "movie1",
                theaterId: "1",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(3600 * 3),
                price: ShowtimePrice(
                    basePrice: 280,
                    weekendPrice: nil,
                    holidayPrice: nil,
                    studentPrice: nil,
                    seniorPrice: nil,
                    childPrice: nil,
                    vipPrice: nil,
                    discounts: []  // 添加空的折扣陣列
                ),
                status: .onSale,
                availableSeats: 80
            ),
            MovieShowtime(
                id: "2",
                movieId: "movie2",
                theaterId: "2",
                startTime: Date().addingTimeInterval(3600 * 4),
                endTime: Date().addingTimeInterval(3600 * 6),
                price: ShowtimePrice(
                    basePrice: 380,
                    weekendPrice: nil,
                    holidayPrice: nil,
                    studentPrice: nil,
                    seniorPrice: nil,
                    childPrice: nil,
                    vipPrice: nil,
                    discounts: []  // 添加空的折扣陣列
                ),
                status: .almostFull,
                availableSeats: 20
            )
        ]
        
        
        showtimes = showtimeData
        filterShowtimes()
    }
    
    private func filterShowtimes() {
        let calendar = Calendar.current
        filteredShowtimes = showtimes.filter { showtime in
            // 首先過濾日期
            let isSameDay = calendar.isDate(showtime.startTime, inSameDayAs: selectedDate)
            
            // 然後根據選擇的狀態過濾
            let statusMatch: Bool
            switch segmentedControl.selectedSegmentIndex {
            case 0: // 全部
                statusMatch = true
            case 1: // 售票中
                statusMatch = showtime.status == .onSale
            case 2: // 即將額滿
                statusMatch = showtime.status == .almostFull
            case 3: // 已售完
                statusMatch = showtime.status == .soldOut
            case 4: // 已取消
                statusMatch = showtime.status == .canceled
            default:
                statusMatch = true
            }
            
            return isSameDay && statusMatch
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func filterChanged(_ sender: UISegmentedControl) {
        filterShowtimes()
    }
    
    @objc private func refreshData() {
        // 模擬重新載入資料
        loadInitialData()
    }
    
    @objc private func addShowtimeTapped() {
        let alert = UIAlertController(title: "新增場次", message: nil, preferredStyle: .alert)
        
        // 選擇影廳
        alert.addTextField { textField in
            textField.placeholder = "選擇影廳"
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            textField.inputView = pickerView
        }
        
        // 選擇時間
        alert.addTextField { textField in
            textField.placeholder = "開始時間"
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .time
            datePicker.preferredDatePickerStyle = .wheels
            textField.inputView = datePicker
        }
        
        // 設定票價
        alert.addTextField { textField in
            textField.placeholder = "基本票價"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            guard let theaterId = alert.textFields?[0].text,
                  let startTimeStr = alert.textFields?[1].text,
                  let priceStr = alert.textFields?[2].text,
                  let price = Double(priceStr) else { return }
            
            // 這裡應該要有更完整的資料驗證
            let newShowtime = MovieShowtime(
                id: UUID().uuidString,
                movieId: "movie1", // 應該要從電影列表中選擇
                theaterId: theaterId,
                startTime: Date(),
                endTime: Date().addingTimeInterval(7200),
                price: ShowtimePrice(
                    basePrice: price,
                    weekendPrice: nil,
                    holidayPrice: nil,
                    studentPrice: nil,
                    seniorPrice: nil,
                    childPrice: nil,
                    vipPrice: nil,
                    discounts: []
                ),
                status: .onSale,
                availableSeats: 100
            )
            
            
            self?.showtimes.append(newShowtime)
            self?.filterShowtimes()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ShowtimeManagementViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredShowtimes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShowtimeCell", for: indexPath) as? ShowtimeTableViewCell else {
            return UITableViewCell()
        }
        
        let showtime = filteredShowtimes[indexPath.row]
        cell.configure(with: showtime)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let showtime = filteredShowtimes[indexPath.row]
        showShowtimeDetails(showtime)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        
        let showtime = filteredShowtimes[indexPath.row]
        
        // 取消場次
        let cancel = UIContextualAction(style: .destructive, title: "取消") { [weak self] _, _, completion in
            var updatedShowtime = showtime
            updatedShowtime.status = .canceled
            
            if let index = self?.showtimes.firstIndex(where: { $0.id == showtime.id }) {
                self?.showtimes[index] = updatedShowtime
                self?.filterShowtimes()
            }
            
            completion(true)
        }
        
        // 修改狀態
        let status = UIContextualAction(style: .normal, title: "狀態") { [weak self] _, _, completion in
            let alert = UIAlertController(title: "更改狀態", message: nil, preferredStyle: .actionSheet)
            
            [MovieShowtime.ShowtimeStatus.onSale,
             .almostFull,
             .soldOut,
             .canceled].forEach { status in
                let action = UIAlertAction(title: status.rawValue, style: .default) { _ in
                    var updatedShowtime = showtime
                    updatedShowtime.status = status
                    
                    if let index = self?.showtimes.firstIndex(where: { $0.id == showtime.id }) {
                        self?.showtimes[index] = updatedShowtime
                        self?.filterShowtimes()
                    }
                }
                alert.addAction(action)
            }
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            self?.present(alert, animated: true)
            completion(true)
        }
        
        status.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [cancel, status])
    }
    
    private func showShowtimeDetails(_ showtime: MovieShowtime) {
        // 這裡可以實作場次詳細資訊的顯示邏輯
        let alert = UIAlertController(
            title: "場次詳細資訊",
            message: """
                開始時間: \(formatDate(showtime.startTime))
                結束時間: \(formatDate(showtime.endTime))
                影廳: \(theaters.first(where: { $0.id == showtime.theaterId })?.name ?? "未知")
                票價: \(showtime.price.basePrice)
                剩餘座位: \(showtime.availableSeats)
                狀態: \(showtime.status.rawValue)
                """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - UICalendarViewDelegate
extension ShowtimeManagementViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let date = Calendar.current.date(from: dateComponents ?? DateComponents()) else { return }
        selectedDate = date
        filterShowtimes()
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        // 這裡可以加入日期裝飾，例如標記有場次的日期
        return nil
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension ShowtimeManagementViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return theaters.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return theaters[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let textField = pickerView.inputView as? UITextField {
            textField.text = theaters[row].name
        }
    }
}
