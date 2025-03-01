import UIKit
import Combine

class ShowtimeManagementViewController: UIViewController {
    // MARK: - Properties
    let viewModel: ShowtimeManagementViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true  // 允許垂直滾動
        scrollView.showsVerticalScrollIndicator = true  // 顯示滾動條
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
        calendar.tintColor = .systemBlue
        calendar.translatesAutoresizingMaskIntoConstraints = false
        
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
        table.register(ShowtimeTableViewCell.self, forCellReuseIdentifier: "ShowtimeTableViewCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        table.isScrollEnabled = true  // 確保可以滾動
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
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        initializeCalendar()
        viewModel.loadInitialData()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "場次管理"
        setupNavigationBar()
        setupConstraints()
    }
    
    private func initializeCalendar() {
        let today = Calendar.current.startOfDay(for: Date())
        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            dateSelection.setSelected(Calendar.current.dateComponents([.year, .month, .day], from: today), animated: false)
        }
    }
    
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshData)
        )
    }
    
    private func setupBindings() {
        viewModel.$selectedDate
            .removeDuplicates()
            .sink { [weak self] date in
                print("📅 選擇日期：\(date)")
                self?.viewModel.loadBookingRecords(for: date)
            }
            .store(in: &cancellables)
        
        viewModel.$filteredShowtimes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showtimes in
                self?.tableView.reloadData()
                print("🔄 更新資料：\(showtimes.count) 筆")
            }
            .store(in: &cancellables)
        
        
        viewModel.$datesWithData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateCalendarDecorations()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
    
    
    private func setupConstraints() {
        view.addSubview(scrollView)
        view.addSubview(loadingIndicator)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(calendarView)
        contentView.addSubview(segmentedControl)
        contentView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            // 修改此行：刪除 width 約束
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // 保留 tableView 高度約束
        let tableViewHeight = tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        tableViewHeight.priority = .defaultHigh
        tableViewHeight.isActive = true
    }
    
    
    // MARK: - Helper Methods
    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    private func updateCalendarDecorations() {
        let components = Calendar.current.dateComponents([.year, .month], from: viewModel.selectedDate)
        calendarView.reloadDecorations(forDateComponents: [components], animated: true)
    }
    
    // MARK: - Actions
    @objc private func filterChanged(_ sender: UISegmentedControl) {
        let statuses: [MovieShowtime.ShowtimeStatus?] = [nil, .onSale, .almostFull, .soldOut, .canceled]
        viewModel.updateSelectedStatus(statuses[sender.selectedSegmentIndex])
        viewModel.filterShowtimes(date: viewModel.selectedDate, status: viewModel.selectedStatus)
    }
    
    
    @objc private func refreshData() {
        viewModel.loadInitialData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ShowtimeManagementViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of filtered showtimes: \(viewModel.filteredShowtimes.count)")
        return viewModel.filteredShowtimes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Dequeuing cell at index path: \(indexPath)")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShowtimeTableViewCell", for: indexPath) as? ShowtimeTableViewCell else {
            print("Failed to dequeue ShowtimeTableViewCell")
            return UITableViewCell()
        }
        
        let showtime = viewModel.filteredShowtimes[indexPath.row]
        cell.configure(with: showtime)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let showtime = viewModel.filteredShowtimes[indexPath.row]
        let message = viewModel.getShowtimeDetailsMessage(showtime)
        
        let alert = UIAlertController(title: "場次詳細資訊", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICalendarViewDelegate
extension ShowtimeManagementViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let date = Calendar.current.date(from: dateComponents ?? DateComponents()) else { return }
        
        // 重置狀態過濾
        viewModel.selectedStatus = nil
        segmentedControl.selectedSegmentIndex = 0
        
        viewModel.selectedDate = date
        viewModel.loadBookingRecords(for: date)  // 直接載入選擇日期的資料
    }
    
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        return viewModel.isDateHasData(date) ? .default(color: .systemBlue) : nil
    }
    
    func calendarView(_ calendarView: UICalendarView, didChangeVisibleMonths months: [DateComponents]) {
        // 為每個可見的月份載入資料
        months.forEach { month in
            if let date = Calendar.current.date(from: month) {
                viewModel.loadBookingRecords(for: date)
            }
        }
    }
}

