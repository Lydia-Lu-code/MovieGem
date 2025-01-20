import UIKit
import Combine

class ShowtimeManagementViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: ShowtimeManagementViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var calendarView: UICalendarView = {
        let calendar = UICalendarView()
        calendar.calendar = .current
        calendar.locale = .current
        calendar.delegate = self
        calendar.translatesAutoresizingMaskIntoConstraints = false
        
        // 設置日期範圍
        let cal = Calendar.current
        let pastDate = cal.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let futureDate = cal.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        calendar.availableDateRange = DateInterval(start: pastDate, end: futureDate)
        
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
    
    // MARK: - Initialization
    init(viewModel: ShowtimeManagementViewModel = ShowtimeManagementViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ShowtimeManagementViewModel()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // 載入當天的資料，去除時間部分
        let today = Calendar.current.startOfDay(for: Date())
        viewModel.selectedDate = today
        viewModel.loadBookingRecords(for: today)
        
        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            dateSelection.setSelected(Calendar.current.dateComponents([.year, .month, .day], from: today), animated: false)
        }
    }
    
    private func setupBindings() {
        // 確保每次只觸發一次更新
        viewModel.$filteredShowtimes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filteredShowtimes in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // 其他 binding 保持不變
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            // 顯示載入指示器
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        } else {
            // 恢復重新整理按鈕
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(refreshData)
            )
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "場次管理"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshData)
        )
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(calendarView)
        contentView.addSubview(segmentedControl)
        contentView.addSubview(tableView)
        
        // 設定 contentView 的寬度約束
        let contentViewWidth = contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        contentViewWidth.priority = .required // 提高優先級
        
        // 設定最小高度約束
        let contentViewMinHeight = contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
        contentViewMinHeight.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            // ScrollView 約束
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ContentView 約束
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentViewWidth,
            contentViewMinHeight,
            
            // Calendar 約束
            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // SegmentedControl 約束
            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // TableView 約束
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
    }

    // 更新 viewDidLayoutSubviews 方法
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 計算所需的總高度
        let contentHeight = calendarView.frame.height +
                           16 + // 間距
                           segmentedControl.frame.height +
                           16 + // 間距
                           max(tableView.contentSize.height, 300) +
                           32 // 上下邊距
        
        // 確保 contentView 至少和 scrollView 一樣高
        let minHeight = max(contentHeight, scrollView.frame.height)
        
        // 更新 contentView 的高度約束
        if let existingConstraint = contentView.constraints.first(where: { $0.firstAttribute == .height }) {
            existingConstraint.constant = minHeight
        } else {
            let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: minHeight)
            heightConstraint.priority = .defaultHigh // 設置優先級
            heightConstraint.isActive = true
        }
        
        // 強制更新佈局
        view.layoutIfNeeded()
    }
    
    @objc private func filterChanged(_ sender: UISegmentedControl) {
        let statuses: [MovieShowtime.ShowtimeStatus?] = [nil, .onSale, .almostFull, .soldOut, .canceled]
        viewModel.updateSelectedStatus(statuses[sender.selectedSegmentIndex])
        viewModel.filterShowtimes(date: viewModel.selectedDate, status: viewModel.selectedStatus)
    }
    
    
    
    @objc private func refreshData() {
        viewModel.loadData()
    }
    
    private func showShowtimeDetails(_ showtime: MovieShowtime) {
        let alert = UIAlertController(
            title: "場次詳細資訊",
            message: """
                開始時間: \(viewModel.formatDate(showtime.startTime))
                結束時間: \(viewModel.formatDate(showtime.endTime))
                影廳: \(viewModel.getTheaterName(for: showtime.theaterId))
                票價: \(showtime.price.basePrice)
                剩餘座位: \(showtime.availableSeats)
                狀態: \(showtime.status.rawValue)
                """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    
    
}

// MARK: - UITableViewDataSource & Delegate
extension ShowtimeManagementViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredShowtimes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShowtimeCell", for: indexPath) as? ShowtimeTableViewCell else {
            return UITableViewCell()
        }
        
        let showtime = viewModel.filteredShowtimes[indexPath.row]
        cell.configure(with: showtime)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let showtime = viewModel.filteredShowtimes[indexPath.row]
        showShowtimeDetails(showtime)
    }
}

extension ShowtimeManagementViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let date = Calendar.current.date(from: dateComponents ?? DateComponents()) else {
            return
        }
        
        
        // 重置狀態過濾
        viewModel.selectedStatus = nil  // 修改這裡
        segmentedControl.selectedSegmentIndex = 0
        
        viewModel.selectedDate = date
        viewModel.loadBookingRecords(for: date)
    }
    

}

