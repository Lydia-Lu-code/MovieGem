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
        calendar.tintColor = .systemBlue  // 設置點的顏色
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
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // 先設置日曆選擇
        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            dateSelection.setSelected(
                Calendar.current.dateComponents([.year, .month, .day], from: today),
                animated: false
            )
        }
        
        // 然後載入數據
        viewModel.selectedDate = today
        viewModel.loadBookingRecords(for: today)
    }
    
    
    private func initializeData() {
        print("🚀 初始化數據開始")
        viewModel.loadData()
        
        let today = Calendar.current.startOfDay(for: Date())
        print("📅 設置今天日期：", today)
        viewModel.selectedDate = today
        
        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: today)
            print("🎯 設置日曆選中狀態：", components)
            dateSelection.setSelected(components, animated: false)
        }
        
        Task {
            print("🌐 開始載入網路數據")
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                viewModel.loadBookingRecords(for: today)
            }
        }
    }
    
    func updateCalendarDecorations() {
        // 直接使用當前選中的日期來更新裝飾
        let components = Calendar.current.dateComponents([.year, .month], from: viewModel.selectedDate)
        calendarView.reloadDecorations(
            forDateComponents: [components],
            animated: true
        )
    }
    

    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else {
            return nil
        }
        return viewModel.isDateHasData(date) ? .default(color: .systemBlue) : nil
    }
    

    
    private func setupBindings() {
        
        // 先監聽數據載入狀態
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
        
        // 監聽有數據的日期變化
        viewModel.$datesWithData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dates in
                print("📊 datesWithData 更新：", dates)
                self?.updateCalendarDecorations()
            }
            .store(in: &cancellables)

        
        // 最後監聽過濾後的數據變化
        viewModel.$filteredShowtimes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
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
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                    
            // ContentView 約束
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
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
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
            
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
            message: viewModel.getShowtimeDetailsMessage(showtime),
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
    
    func calendarView(_ calendarView: UICalendarView, didChangeVisibleMonths months: [DateComponents]) {
        // 為每個可見的月份載入資料
        months.forEach { month in
            if let date = Calendar.current.date(from: month) {
                viewModel.loadBookingRecords(for: date)
            }
        }
    }
    
}


//import UIKit
//import Combine
//
//class ShowtimeManagementViewController: UIViewController {
//    // MARK: - Properties
//    private let viewModel: ShowtimeManagementViewModel
//    private var cancellables = Set<AnyCancellable>()
//    
//    
//    // MARK: - UI Components
//    private lazy var scrollView: UIScrollView = {
//        let scrollView = UIScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.alwaysBounceVertical = true
//        return scrollView
//    }()
//    
//    private lazy var contentView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private lazy var calendarView: UICalendarView = {
//        let calendar = UICalendarView()
//        calendar.calendar = .current
//        calendar.locale = .current
//        calendar.delegate = self
//        calendar.tintColor = .systemBlue  // 設置點的顏色
//        calendar.translatesAutoresizingMaskIntoConstraints = false
//        
//        // 設置日期範圍
//        let cal = Calendar.current
//        let pastDate = cal.date(byAdding: .year, value: -1, to: Date()) ?? Date()
//        let futureDate = cal.date(byAdding: .year, value: 1, to: Date()) ?? Date()
//        calendar.availableDateRange = DateInterval(start: pastDate, end: futureDate)
//        
//        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
//        calendar.selectionBehavior = dateSelection
//        
//        return calendar
//    }()
//    
//    
//    private lazy var segmentedControl: UISegmentedControl = {
//        let items = ["全部", "售票中", "即將額滿", "已售完", "已取消"]
//        let control = UISegmentedControl(items: items)
//        control.selectedSegmentIndex = 0
//        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
//        control.translatesAutoresizingMaskIntoConstraints = false
//        return control
//    }()
//    
//    private lazy var tableView: UITableView = {
//        let table = UITableView(frame: .zero, style: .insetGrouped)
//        table.delegate = self
//        table.dataSource = self
//        table.register(ShowtimeTableViewCell.self, forCellReuseIdentifier: "ShowtimeCell")
//        table.translatesAutoresizingMaskIntoConstraints = false
//        table.rowHeight = UITableView.automaticDimension
//        table.estimatedRowHeight = 80
//        return table
//    }()
//    
//    // MARK: - Initialization
//    init(viewModel: ShowtimeManagementViewModel = ShowtimeManagementViewModel()) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        self.viewModel = ShowtimeManagementViewModel()
//        super.init(coder: coder)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupBindings()
//        
//        // 確保 TableView 的設置正確
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.rowHeight = UITableView.automaticDimension
//        tableView.estimatedRowHeight = 80
//        
//        let today = Calendar.current.startOfDay(for: Date())
//        
//        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
//            dateSelection.setSelected(
//                Calendar.current.dateComponents([.year, .month, .day], from: today),
//                animated: false
//            )
//        }
//        
//        viewModel.selectedDate = today
//        viewModel.loadBookingRecords(for: today)
//    }
//    
//    
////    override func viewDidLoad() {
////        super.viewDidLoad()
////        setupUI()
////        setupBindings()
////
////        // 確保 TableView 可以正確顯示
////        tableView.estimatedRowHeight = 80
////        tableView.rowHeight = UITableView.automaticDimension
////
////        let today = Calendar.current.startOfDay(for: Date())
////
////        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
////            dateSelection.setSelected(
////                Calendar.current.dateComponents([.year, .month, .day], from: today),
////                animated: false
////            )
////        }
////
////        viewModel.selectedDate = today
////        viewModel.loadBookingRecords(for: today)
////    }
//    
////    override func viewDidLoad() {
////        super.viewDidLoad()
////        setupUI()
////        setupBindings()
////
////        let today = Calendar.current.startOfDay(for: Date())
////
////        // 先設置日曆選擇
////        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
////            dateSelection.setSelected(
////                Calendar.current.dateComponents([.year, .month, .day], from: today),
////                animated: false
////            )
////        }
////
////        // 然後載入數據
////        viewModel.selectedDate = today
////        viewModel.loadBookingRecords(for: today)
////
////    }
//    
//    
//    private func initializeData() {
//        viewModel.loadData()
//        
//        let today = Calendar.current.startOfDay(for: Date())
//        viewModel.selectedDate = today
//        
//        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
//            let components = Calendar.current.dateComponents([.year, .month, .day], from: today)
//            dateSelection.setSelected(components, animated: false)
//        }
//        
//        Task {
//            try? await Task.sleep(nanoseconds: 100_000_000)
//            await MainActor.run {
//                viewModel.loadBookingRecords(for: today)
//            }
//        }
//    }
//    
//    func updateCalendarDecorations() {
//        // 獲取當前月份的所有日期組件
//        let calendar = Calendar.current
//        let year = calendar.component(.year, from: viewModel.selectedDate)
//        let month = calendar.component(.month, from: viewModel.selectedDate)
//        
//        // 創建一個空的日期組件數組
//        var componentsToReload: [DateComponents] = []
//        
//        // 遍歷整個月份
//        if let range = calendar.range(of: .day, in: .month, for: viewModel.selectedDate) {
//            for day in range {
//                var components = DateComponents()
//                components.year = year
//                components.month = month
//                components.day = day
//                componentsToReload.append(components)
//            }
//        }
//        
//        // 重新加載所有日期的裝飾
//        calendarView.reloadDecorations(forDateComponents: componentsToReload, animated: true)
//    }
//    
////    func updateCalendarDecorations() {
////        // 直接使用當前選中的日期來更新裝飾
////        let components = Calendar.current.dateComponents([.year, .month], from: viewModel.selectedDate)
////        calendarView.reloadDecorations(
////            forDateComponents: [components],
////            animated: true
////        )
////    }
//    
//
//    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
//        guard let date = Calendar.current.date(from: dateComponents) else {
//            return nil
//        }
//        return viewModel.isDateHasData(date) ? .default(color: .systemBlue) : nil
//    }
//    
//    private func setupBindings() {
//        // 監聽載入狀態
//        viewModel.$isLoading
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isLoading in
//                self?.updateLoadingState(isLoading)
//            }
//            .store(in: &cancellables)
//        
//        // 監聽數據變化
//        viewModel.$filteredShowtimes
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] showtimes in
//                print("數據更新：\(showtimes.count) 條記錄")
//                self?.tableView.reloadData()
//                self?.view.layoutIfNeeded()
//            }
//            .store(in: &cancellables)
//        
//        // 監聽錯誤
//        viewModel.$error
//            .receive(on: DispatchQueue.main)
//            .compactMap { $0 }
//            .sink { [weak self] error in
//                self?.showError(error)
//            }
//            .store(in: &cancellables)
//    }
//
//    private func showError(_ error: Error) {
//        let alert = UIAlertController(
//            title: "載入失敗",
//            message: "無法載入場次資料：\(error.localizedDescription)",
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "重試", style: .default) { [weak self] _ in
//            self?.viewModel.loadBookingRecords(for: self?.viewModel.selectedDate ?? Date())
//        })
//        alert.addAction(UIAlertAction(title: "確定", style: .cancel))
//        present(alert, animated: true)
//    }
//    
////    private func setupBindings() {
////        // 原有的綁定保持不變
////        viewModel.$isLoading
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] isLoading in
////                self?.updateLoadingState(isLoading)
////            }
////            .store(in: &cancellables)
////        
////        viewModel.$datesWithData
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] dates in
////                self?.updateCalendarDecorations()
////            }
////            .store(in: &cancellables)
////        
////        // 修改這部分來處理 TableView 高度更新
////        viewModel.$filteredShowtimes
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] showtimes in
////                self?.tableView.reloadData()
////                self?.updateTableViewHeight()
////            }
////            .store(in: &cancellables)
////    }
//
//    private func updateTableViewHeight() {
//        tableView.layoutIfNeeded()
//        
//        let contentHeight = calendarView.frame.height +
//                           16 + // 間距
//                           segmentedControl.frame.height +
//                           16 + // 間距
//                           tableView.contentSize.height +
//                           32  // 額外間距
//        
//        // 確保最小高度不小於 ScrollView
//        let minHeight = max(contentHeight, scrollView.frame.height)
//        
//        // 更新 ContentView 高度
//        contentView.frame.size.height = minHeight
//        
//        // 強制更新佈局
//        view.layoutIfNeeded()
//    }
//    
////    private func setupBindings() {
////
////        // 先監聽數據載入狀態
////        viewModel.$isLoading
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] isLoading in
////                self?.updateLoadingState(isLoading)
////            }
////            .store(in: &cancellables)
////
////        // 監聽有數據的日期變化
////        viewModel.$datesWithData
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] dates in
////                self?.updateCalendarDecorations()
////            }
////            .store(in: &cancellables)
////
////
////        // 最後監聽過濾後的數據變化
////        viewModel.$filteredShowtimes
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] _ in
////                self?.tableView.reloadData()
////            }
////            .store(in: &cancellables)
////
////
////
////        viewModel.$error
////            .receive(on: DispatchQueue.main)
////            .compactMap { $0 }
////            .sink { [weak self] error in
////                self?.showError(error)
////            }
////            .store(in: &cancellables)
////
////
////    }
//    
////    private func showError(_ error: Error) {
////        let alert = UIAlertController(
////            title: "錯誤",
////            message: error.localizedDescription,
////            preferredStyle: .alert
////        )
////        alert.addAction(UIAlertAction(title: "確定", style: .default))
////        present(alert, animated: true)
////    }
//
//    private func updateLoadingState(_ isLoading: Bool) {
//        if isLoading {
//            // 顯示載入指示器
//            let activityIndicator = UIActivityIndicatorView(style: .medium)
//            activityIndicator.startAnimating()
//            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
//        } else {
//            // 恢復重新整理按鈕
//            navigationItem.rightBarButtonItem = UIBarButtonItem(
//                image: UIImage(systemName: "arrow.clockwise"),
//                style: .plain,
//                target: self,
//                action: #selector(refreshData)
//            )
//        }
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        title = "場次管理"
//        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(
//            image: UIImage(systemName: "arrow.clockwise"),
//            style: .plain,
//            target: self,
//            action: #selector(refreshData)
//        )
//        
//        setupConstraints()
//    }
//    
//    private func setupConstraints() {
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
//        
//        contentView.addSubview(calendarView)
//        contentView.addSubview(segmentedControl)
//        contentView.addSubview(tableView)
//        
//        NSLayoutConstraint.activate([
//            // ScrollView 約束
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), // 修改這裡
//            
//            // ContentView 約束 - 修改這部分
//            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//            
//            // Calendar 約束
//            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            // SegmentedControl 約束
//            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
//            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            // TableView 約束
//            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
//        ])
//    }
//    
////    private func setupConstraints() {
////        view.addSubview(scrollView)
////        scrollView.addSubview(contentView)
////        
////        contentView.addSubview(calendarView)
////        contentView.addSubview(segmentedControl)
////        contentView.addSubview(tableView)
////        
////        NSLayoutConstraint.activate([
////             // ScrollView 約束
////             scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
////             scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
////             scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////             scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
////             
////             // ContentView 約束
////             contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
////             contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
////             contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
////             contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
////             contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
////             
////             // Calendar 約束
////             calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
////             calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
////             calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
////             
////             // SegmentedControl 約束
////             segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
////             segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
////             segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
////             
////             // TableView 約束
////             tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
////             tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
////             tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
////             tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
////             // 添加最小高度
////             tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
////         ])
////        
//////        NSLayoutConstraint.activate([
//////            // ScrollView 約束
//////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//////            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//////            
//////            // ContentView 基本約束
//////            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//////            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//////            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//////            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//////            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//////            
//////            // 保留原本的行事曆約束
//////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // SegmentedControl 最小約束
//////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
//////            segmentedControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//////            
//////            // TableView 最小約束
//////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//////        ])
////    }
//
//    // 移除 viewDidLayoutSubviews 中的手動高度計算
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        // 只保留必要的佈局更新
//        tableView.layoutIfNeeded()
//        
//        // 確保 contentView 的最小高度
//        let minHeight = view.frame.height
//        contentView.frame.size.height = max(contentView.frame.size.height, minHeight)
//    }
//    
////    private func setupConstraints() {
////        view.addSubview(scrollView)
////        scrollView.addSubview(contentView)
////        
////        contentView.addSubview(calendarView)
////        contentView.addSubview(segmentedControl)
////        contentView.addSubview(tableView)
////        
////        NSLayoutConstraint.activate([
////            // ScrollView 約束
////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
////            
////            // ContentView 約束
////            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
////            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
////            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
////            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
////            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
////            
////            // Calendar 約束
////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
////            
////            // SegmentedControl 約束
////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
////            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
////            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
////            
////            // TableView 約束
////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
////            // 添加一個固定高度約束，之後再動態調整
////            tableView.heightAnchor.constraint(equalToConstant: 400)
////        ])
////    }
////    
////    override func viewDidLayoutSubviews() {
////        super.viewDidLayoutSubviews()
////        updateTableViewHeight()
////    }
//    
//    @objc private func filterChanged(_ sender: UISegmentedControl) {
//        let statuses: [MovieShowtime.ShowtimeStatus?] = [nil, .onSale, .almostFull, .soldOut, .canceled]
//        viewModel.updateSelectedStatus(statuses[sender.selectedSegmentIndex])
//        viewModel.filterShowtimes(date: viewModel.selectedDate, status: viewModel.selectedStatus)
//    }
//    
//    
//    
//    @objc private func refreshData() {
//        viewModel.loadData()
//    }
//    
//    private func showShowtimeDetails(_ showtime: MovieShowtime) {
//        let alert = UIAlertController(
//            title: "場次詳細資訊",
//            message: viewModel.getShowtimeDetailsMessage(showtime),
//            preferredStyle: .alert
//        )
//        
//        alert.addAction(UIAlertAction(title: "確定", style: .default))
//        present(alert, animated: true)
//    }
//    
//    
//    
//    
//}
//
//// MARK: - UITableViewDataSource & Delegate
//extension ShowtimeManagementViewController: UITableViewDataSource, UITableViewDelegate {
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let count = viewModel.filteredShowtimes.count
//        print("TableView 行數: \(count)") // 添加這行來檢查
//        return count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShowtimeCell", for: indexPath) as? ShowtimeTableViewCell else {
//            return UITableViewCell()
//        }
//        
//        let showtime = viewModel.filteredShowtimes[indexPath.row]
//        cell.configure(with: showtime)
//        print("配置單元格: \(indexPath.row)") // 添加這行來檢查
//        return cell
//    }
//    
////    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
////        return viewModel.filteredShowtimes.count
////    }
////
////    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
////        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShowtimeCell", for: indexPath) as? ShowtimeTableViewCell else {
////            return UITableViewCell()
////        }
////
////        let showtime = viewModel.filteredShowtimes[indexPath.row]
////        cell.configure(with: showtime)
////        return cell
////    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        let showtime = viewModel.filteredShowtimes[indexPath.row]
//        showShowtimeDetails(showtime)
//    }
//    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 80
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
//}
//
//extension ShowtimeManagementViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
//    
//    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
//        guard let date = Calendar.current.date(from: dateComponents ?? DateComponents()) else {
//            return
//        }
//        
//        viewModel.selectedStatus = nil
//        segmentedControl.selectedSegmentIndex = 0
//        
//        viewModel.selectedDate = date
//        viewModel.loadBookingRecords(for: date)
//        
//        // 當資料載入完成後，TableView 會通過 binding 自動更新高度
//    }
//    
////    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
////        guard let date = Calendar.current.date(from: dateComponents ?? DateComponents()) else {
////            return
////        }
////
////
////        // 重置狀態過濾
////        viewModel.selectedStatus = nil  // 修改這裡
////        segmentedControl.selectedSegmentIndex = 0
////
////        viewModel.selectedDate = date
////        viewModel.loadBookingRecords(for: date)
////    }
//    
//    func calendarView(_ calendarView: UICalendarView, didChangeVisibleMonths months: [DateComponents]) {
//        // 為每個可見的月份載入資料
//        months.forEach { month in
//            if let date = Calendar.current.date(from: month) {
//                viewModel.loadBookingRecords(for: date)
//            }
//        }
//    }
//    
//}
//
//
//
////import UIKit
////import Combine
////
////class ShowtimeManagementViewController: UIViewController {
////    // MARK: - Properties
////    private let viewModel: ShowtimeManagementViewModel
////    private var cancellables = Set<AnyCancellable>()
////    
////    
////    // MARK: - UI Components
////    private lazy var scrollView: UIScrollView = {
////        let scrollView = UIScrollView()
////        scrollView.translatesAutoresizingMaskIntoConstraints = false
////        scrollView.alwaysBounceVertical = true
////        return scrollView
////    }()
////    
////    private lazy var contentView: UIView = {
////        let view = UIView()
////        view.translatesAutoresizingMaskIntoConstraints = false
////        return view
////    }()
////    
////    private lazy var calendarView: UICalendarView = {
////        let calendar = UICalendarView()
////        calendar.calendar = .current
////        calendar.locale = .current
////        calendar.delegate = self
////        calendar.tintColor = .systemBlue  // 設置點的顏色
////        calendar.translatesAutoresizingMaskIntoConstraints = false
////        
////        // 設置日期範圍
////        let cal = Calendar.current
////        let pastDate = cal.date(byAdding: .year, value: -1, to: Date()) ?? Date()
////        let futureDate = cal.date(byAdding: .year, value: 1, to: Date()) ?? Date()
////        calendar.availableDateRange = DateInterval(start: pastDate, end: futureDate)
////        
////        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
////        calendar.selectionBehavior = dateSelection
////        
////        return calendar
////    }()
////    
////    
////    private lazy var segmentedControl: UISegmentedControl = {
////        let items = ["全部", "售票中", "即將額滿", "已售完", "已取消"]
////        let control = UISegmentedControl(items: items)
////        control.selectedSegmentIndex = 0
////        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
////        control.translatesAutoresizingMaskIntoConstraints = false
////        return control
////    }()
////    
////    private lazy var tableView: UITableView = {
////        let table = UITableView(frame: .zero, style: .insetGrouped)
////        table.delegate = self
////        table.dataSource = self
////        table.register(ShowtimeTableViewCell.self, forCellReuseIdentifier: "ShowtimeCell")
////        table.translatesAutoresizingMaskIntoConstraints = false
////        table.rowHeight = UITableView.automaticDimension
////        table.estimatedRowHeight = 80
////        return table
////    }()
////    
////    // MARK: - Initialization
////    init(viewModel: ShowtimeManagementViewModel = ShowtimeManagementViewModel()) {
////        self.viewModel = viewModel
////        super.init(nibName: nil, bundle: nil)
////    }
////    
////    required init?(coder: NSCoder) {
////        self.viewModel = ShowtimeManagementViewModel()
////        super.init(coder: coder)
////    }
////    
////    override func viewDidLoad() {
////        super.viewDidLoad()
////        setupUI()
////        setupBindings()
////        
////        // 確保 TableView 的設置正確
////        tableView.delegate = self
////        tableView.dataSource = self
////        tableView.rowHeight = UITableView.automaticDimension
////        tableView.estimatedRowHeight = 80
////        
////        let today = Calendar.current.startOfDay(for: Date())
////        
////        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
////            dateSelection.setSelected(
////                Calendar.current.dateComponents([.year, .month, .day], from: today),
////                animated: false
////            )
////        }
////        
////        viewModel.selectedDate = today
////        viewModel.loadBookingRecords(for: today)
////    }
////    
////    
//////    override func viewDidLoad() {
//////        super.viewDidLoad()
//////        setupUI()
//////        setupBindings()
//////        
//////        // 確保 TableView 可以正確顯示
//////        tableView.estimatedRowHeight = 80
//////        tableView.rowHeight = UITableView.automaticDimension
//////        
//////        let today = Calendar.current.startOfDay(for: Date())
//////        
//////        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
//////            dateSelection.setSelected(
//////                Calendar.current.dateComponents([.year, .month, .day], from: today),
//////                animated: false
//////            )
//////        }
//////        
//////        viewModel.selectedDate = today
//////        viewModel.loadBookingRecords(for: today)
//////    }
////    
//////    override func viewDidLoad() {
//////        super.viewDidLoad()
//////        setupUI()
//////        setupBindings()
//////        
//////        let today = Calendar.current.startOfDay(for: Date())
//////        
//////        // 先設置日曆選擇
//////        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
//////            dateSelection.setSelected(
//////                Calendar.current.dateComponents([.year, .month, .day], from: today),
//////                animated: false
//////            )
//////        }
//////        
//////        // 然後載入數據
//////        viewModel.selectedDate = today
//////        viewModel.loadBookingRecords(for: today)
//////        
//////    }
////    
////    
////    private func initializeData() {
////        viewModel.loadData()
////        
////        let today = Calendar.current.startOfDay(for: Date())
////        viewModel.selectedDate = today
////        
////        if let dateSelection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
////            let components = Calendar.current.dateComponents([.year, .month, .day], from: today)
////            dateSelection.setSelected(components, animated: false)
////        }
////        
////        Task {
////            try? await Task.sleep(nanoseconds: 100_000_000)
////            await MainActor.run {
////                viewModel.loadBookingRecords(for: today)
////            }
////        }
////    }
////    
////    func updateCalendarDecorations() {
////        // 直接使用當前選中的日期來更新裝飾
////        let components = Calendar.current.dateComponents([.year, .month], from: viewModel.selectedDate)
////        calendarView.reloadDecorations(
////            forDateComponents: [components],
////            animated: true
////        )
////    }
////    
////
////    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
////        guard let date = Calendar.current.date(from: dateComponents) else {
////            return nil
////        }
////        return viewModel.isDateHasData(date) ? .default(color: .systemBlue) : nil
////    }
////    
////    private func setupBindings() {
////        // 原有的綁定保持不變
////        viewModel.$isLoading
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] isLoading in
////                self?.updateLoadingState(isLoading)
////            }
////            .store(in: &cancellables)
////        
////        viewModel.$datesWithData
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] dates in
////                self?.updateCalendarDecorations()
////            }
////            .store(in: &cancellables)
////        
////        viewModel.$filteredShowtimes
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] _ in
////                self?.tableView.reloadData()
////                self?.view.layoutIfNeeded() // 強制更新佈局
////            }
////            .store(in: &cancellables)
////        
//////        // 修改這部分來處理 TableView 高度更新
//////        viewModel.$filteredShowtimes
//////            .receive(on: DispatchQueue.main)
//////            .sink { [weak self] showtimes in
//////                self?.tableView.reloadData()
//////                self?.updateTableViewHeight()
//////            }
//////            .store(in: &cancellables)
////    }
////
////    private func updateTableViewHeight() {
////        tableView.layoutIfNeeded()
////        
////        let contentHeight = calendarView.frame.height +
////                           16 + // 間距
////                           segmentedControl.frame.height +
////                           16 + // 間距
////                           tableView.contentSize.height +
////                           32  // 額外間距
////        
////        // 確保最小高度不小於 ScrollView
////        let minHeight = max(contentHeight, scrollView.frame.height)
////        
////        // 更新 ContentView 高度
////        contentView.frame.size.height = minHeight
////        
////        // 強制更新佈局
////        view.layoutIfNeeded()
////    }
////    
//////    private func setupBindings() {
//////        
//////        // 先監聽數據載入狀態
//////        viewModel.$isLoading
//////            .receive(on: DispatchQueue.main)
//////            .sink { [weak self] isLoading in
//////                self?.updateLoadingState(isLoading)
//////            }
//////            .store(in: &cancellables)
//////        
//////        // 監聽有數據的日期變化
//////        viewModel.$datesWithData
//////            .receive(on: DispatchQueue.main)
//////            .sink { [weak self] dates in
//////                self?.updateCalendarDecorations()
//////            }
//////            .store(in: &cancellables)
//////
//////        
//////        // 最後監聽過濾後的數據變化
//////        viewModel.$filteredShowtimes
//////            .receive(on: DispatchQueue.main)
//////            .sink { [weak self] _ in
//////                self?.tableView.reloadData()
//////            }
//////            .store(in: &cancellables)
//////            
//////        
//////        
//////        viewModel.$error
//////            .receive(on: DispatchQueue.main)
//////            .compactMap { $0 }
//////            .sink { [weak self] error in
//////                self?.showError(error)
//////            }
//////            .store(in: &cancellables)
//////
//////        
//////    }
////    
////    private func showError(_ error: Error) {
////        let alert = UIAlertController(
////            title: "錯誤",
////            message: error.localizedDescription,
////            preferredStyle: .alert
////        )
////        alert.addAction(UIAlertAction(title: "確定", style: .default))
////        present(alert, animated: true)
////    }
////
////    private func updateLoadingState(_ isLoading: Bool) {
////        if isLoading {
////            // 顯示載入指示器
////            let activityIndicator = UIActivityIndicatorView(style: .medium)
////            activityIndicator.startAnimating()
////            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
////        } else {
////            // 恢復重新整理按鈕
////            navigationItem.rightBarButtonItem = UIBarButtonItem(
////                image: UIImage(systemName: "arrow.clockwise"),
////                style: .plain,
////                target: self,
////                action: #selector(refreshData)
////            )
////        }
////    }
////    
////    private func setupUI() {
////        view.backgroundColor = .systemBackground
////        title = "場次管理"
////        
////        navigationItem.rightBarButtonItem = UIBarButtonItem(
////            image: UIImage(systemName: "arrow.clockwise"),
////            style: .plain,
////            target: self,
////            action: #selector(refreshData)
////        )
////        
////        setupConstraints()
////    }
////    
////    private func setupConstraints() {
////        view.addSubview(scrollView)
////        scrollView.addSubview(contentView)
////        
////        contentView.addSubview(calendarView)
////        contentView.addSubview(segmentedControl)
////        contentView.addSubview(tableView)
////        
////        NSLayoutConstraint.activate([
////            // ScrollView 約束
////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
////            
////            // ContentView 約束
////            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
////            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
////            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
////            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
////            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
////            
////            // Calendar 約束
////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
////            
////            // SegmentedControl 約束
////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
////            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
////            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
////            
////            // TableView 約束
////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
////        ])
////    }
////
////    // 修改數據更新方法
////    override func viewDidLayoutSubviews() {
////        super.viewDidLayoutSubviews()
////        
////        // 計算 tableView 的內容高度
////        tableView.layoutIfNeeded()
////        let tableViewHeight = max(tableView.contentSize.height, 200)
////        
////        // 計算整個內容的總高度
////        let totalHeight = calendarView.frame.height +
////                         16 + // 間距
////                         segmentedControl.frame.height +
////                         16 + // 間距
////                         tableViewHeight +
////                         32  // 上下邊距
////        
////        // 更新 contentView 的高度
////        let minHeight = max(totalHeight, scrollView.frame.height)
////        contentView.frame.size.height = minHeight
////    }
////    
//////    private func setupConstraints() {
//////        view.addSubview(scrollView)
//////        scrollView.addSubview(contentView)
//////        
//////        contentView.addSubview(calendarView)
//////        contentView.addSubview(segmentedControl)
//////        contentView.addSubview(tableView)
//////        
//////        NSLayoutConstraint.activate([
//////            // ScrollView 約束
//////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//////            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//////            
//////            // ContentView 約束
//////            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//////            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//////            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//////            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//////            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//////            
//////            // Calendar 約束
//////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // SegmentedControl 約束
//////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
//////            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // TableView 約束
//////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//////        ])
//////    }
////
//////    // 修改數據更新方法
//////    override func viewDidLayoutSubviews() {
//////        super.viewDidLayoutSubviews()
//////        
//////        // 計算 tableView 的內容高度
//////        tableView.layoutIfNeeded()
//////        let tableViewHeight = max(tableView.contentSize.height, 200)
//////        
//////        // 計算整個內容的總高度
//////        let totalHeight = calendarView.frame.height +
//////                         16 + // 間距
//////                         segmentedControl.frame.height +
//////                         16 + // 間距
//////                         tableViewHeight +
//////                         32  // 上下邊距
//////        
//////        // 更新 contentView 的高度
//////        let minHeight = max(totalHeight, scrollView.frame.height)
//////        contentView.frame.size.height = minHeight
//////    }
////    
//////    private func setupConstraints() {
//////        view.addSubview(scrollView)
//////        scrollView.addSubview(contentView)
//////        
//////        contentView.addSubview(calendarView)
//////        contentView.addSubview(segmentedControl)
//////        contentView.addSubview(tableView)
//////        
//////        NSLayoutConstraint.activate([
//////            // ScrollView 約束
//////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//////            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//////            
//////            // ContentView 約束
//////            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//////            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//////            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//////            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//////            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//////            
//////            // Calendar 約束
//////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // SegmentedControl 約束
//////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
//////            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // TableView 約束
//////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//////        ])
//////    }
////
////    
//////    private func setupConstraints() {
//////        view.addSubview(scrollView)
//////        scrollView.addSubview(contentView)
//////        
//////        contentView.addSubview(calendarView)
//////        contentView.addSubview(segmentedControl)
//////        contentView.addSubview(tableView)
//////        
//////        NSLayoutConstraint.activate([
//////            // ScrollView 約束
//////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//////            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//////            
//////            // ContentView 約束
//////            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//////            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//////            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//////            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//////            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//////            
//////            // Calendar 約束
//////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // SegmentedControl 約束
//////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
//////            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // TableView 約束 - 修改這部分
//////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//////            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200) // 確保最小高度
//////        ])
//////        
//////        // 設置優先級
//////        calendarView.setContentHuggingPriority(.defaultHigh, for: .vertical)
//////        calendarView.setContentCompressionResistancePriority(.required, for: .vertical)
//////        
//////        tableView.setContentHuggingPriority(.defaultLow, for: .vertical)
//////        tableView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
//////    }
////
//////    override func viewDidLayoutSubviews() {
//////        super.viewDidLayoutSubviews()
//////        
//////        // 更新 contentView 的高度
//////        let totalHeight = calendarView.frame.height +
//////                         16 + // 間距
//////                         segmentedControl.frame.height +
//////                         16 + // 間距
//////                         max(tableView.contentSize.height, 200) // 使用 tableView 的實際內容高度
//////        
//////        let minHeight = max(totalHeight, scrollView.frame.height)
//////        
//////        // 更新 contentView 的高度
//////        if contentView.frame.height != minHeight {
//////            contentView.frame.size.height = minHeight
//////        }
//////    }
////    
//////    private func setupConstraints() {
//////        view.addSubview(scrollView)
//////        scrollView.addSubview(contentView)
//////        
//////        contentView.addSubview(calendarView)
//////        contentView.addSubview(segmentedControl)
//////        contentView.addSubview(tableView)
//////        
//////        NSLayoutConstraint.activate([
//////            // ScrollView 約束
//////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//////            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//////            
//////            // ContentView 基本約束
//////            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//////            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//////            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//////            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//////            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//////            
//////            // 保留原本的行事曆約束
//////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // SegmentedControl 最小約束
//////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
//////            segmentedControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//////            
//////            // TableView 最小約束
//////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//////        ])
//////    }
//////
//////    // 移除 viewDidLayoutSubviews 中的手動高度計算
//////    override func viewDidLayoutSubviews() {
//////        super.viewDidLayoutSubviews()
//////        
//////        // 只保留必要的佈局更新
//////        tableView.layoutIfNeeded()
//////        
//////        // 確保 contentView 的最小高度
//////        let minHeight = view.frame.height
//////        contentView.frame.size.height = max(contentView.frame.size.height, minHeight)
//////    }
////    
//////    private func setupConstraints() {
//////        view.addSubview(scrollView)
//////        scrollView.addSubview(contentView)
//////        
//////        contentView.addSubview(calendarView)
//////        contentView.addSubview(segmentedControl)
//////        contentView.addSubview(tableView)
//////        
//////        // 設定 contentView 的寬度約束
//////        let contentViewWidth = contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
//////        contentViewWidth.priority = .required // 提高優先級
//////        
//////        // 設定最小高度約束
//////        let contentViewMinHeight = contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
//////        contentViewMinHeight.priority = .defaultHigh
//////        
//////        NSLayoutConstraint.activate([
//////            // ScrollView 約束
//////            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//////            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//////            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//////            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//////                    
//////            // ContentView 約束
//////            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
//////            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
//////            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
//////            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
//////            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
//////            
//////            // Calendar 約束
//////            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//////            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // SegmentedControl 約束
//////            segmentedControl.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
//////            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//////            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//////            
//////            // TableView 約束
//////            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//////            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//////            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//////            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
//////            
//////        ])
//////    }
//////
//////    // 更新 viewDidLayoutSubviews 方法
//////    override func viewDidLayoutSubviews() {
//////        super.viewDidLayoutSubviews()
//////        
//////        // 計算所需的總高度
//////        let contentHeight = calendarView.frame.height +
//////                           16 + // 間距
//////                           segmentedControl.frame.height +
//////                           16 + // 間距
//////                           max(tableView.contentSize.height, 300) +
//////                           32 // 上下邊距
//////        
//////        // 確保 contentView 至少和 scrollView 一樣高
//////        let minHeight = max(contentHeight, scrollView.frame.height)
//////        
//////        // 更新 contentView 的高度約束
//////        if let existingConstraint = contentView.constraints.first(where: { $0.firstAttribute == .height }) {
//////            existingConstraint.constant = minHeight
//////        } else {
//////            let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: minHeight)
//////            heightConstraint.priority = .defaultHigh // 設置優先級
//////            heightConstraint.isActive = true
//////        }
//////        
//////        // 強制更新佈局
//////        view.layoutIfNeeded()
//////    }
////    
//////    override func viewDidLayoutSubviews() {
//////        super.viewDidLayoutSubviews()
//////        updateTableViewHeight()
//////    }
////    
////    @objc private func filterChanged(_ sender: UISegmentedControl) {
////        let statuses: [MovieShowtime.ShowtimeStatus?] = [nil, .onSale, .almostFull, .soldOut, .canceled]
////        viewModel.updateSelectedStatus(statuses[sender.selectedSegmentIndex])
////        viewModel.filterShowtimes(date: viewModel.selectedDate, status: viewModel.selectedStatus)
////    }
////    
////    
////    
////    @objc private func refreshData() {
////        viewModel.loadData()
////    }
////    
////    private func showShowtimeDetails(_ showtime: MovieShowtime) {
////        let alert = UIAlertController(
////            title: "場次詳細資訊",
////            message: viewModel.getShowtimeDetailsMessage(showtime),
////            preferredStyle: .alert
////        )
////        
////        alert.addAction(UIAlertAction(title: "確定", style: .default))
////        present(alert, animated: true)
////    }
////    
////    
////    
////    
////}
////
////// MARK: - UITableViewDataSource & Delegate
////extension ShowtimeManagementViewController: UITableViewDataSource, UITableViewDelegate {
////    
////    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
////        let count = viewModel.filteredShowtimes.count
////        print("TableView 行數: \(count)") // 添加這行來檢查
////        return count
////    }
////    
////    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
////        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShowtimeCell", for: indexPath) as? ShowtimeTableViewCell else {
////            return UITableViewCell()
////        }
////        
////        let showtime = viewModel.filteredShowtimes[indexPath.row]
////        cell.configure(with: showtime)
////        print("配置單元格: \(indexPath.row)") // 添加這行來檢查
////        return cell
////    }
////    
//////    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//////        return viewModel.filteredShowtimes.count
//////    }
//////    
//////    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//////        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShowtimeCell", for: indexPath) as? ShowtimeTableViewCell else {
//////            return UITableViewCell()
//////        }
//////        
//////        let showtime = viewModel.filteredShowtimes[indexPath.row]
//////        cell.configure(with: showtime)
//////        return cell
//////    }
////    
////    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
////        tableView.deselectRow(at: indexPath, animated: true)
////        let showtime = viewModel.filteredShowtimes[indexPath.row]
////        showShowtimeDetails(showtime)
////    }
////    
////    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
////        return 80
////    }
////    
////    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
////        return UITableView.automaticDimension
////    }
////}
////
////extension ShowtimeManagementViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
////    
////    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
////        guard let date = Calendar.current.date(from: dateComponents ?? DateComponents()) else {
////            return
////        }
////        
////        viewModel.selectedStatus = nil
////        segmentedControl.selectedSegmentIndex = 0
////        
////        viewModel.selectedDate = date
////        viewModel.loadBookingRecords(for: date)
////        
////        // 當資料載入完成後，TableView 會通過 binding 自動更新高度
////    }
////    
//////    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
//////        guard let date = Calendar.current.date(from: dateComponents ?? DateComponents()) else {
//////            return
//////        }
//////        
//////        
//////        // 重置狀態過濾
//////        viewModel.selectedStatus = nil  // 修改這裡
//////        segmentedControl.selectedSegmentIndex = 0
//////        
//////        viewModel.selectedDate = date
//////        viewModel.loadBookingRecords(for: date)
//////    }
////    
////    func calendarView(_ calendarView: UICalendarView, didChangeVisibleMonths months: [DateComponents]) {
////        // 為每個可見的月份載入資料
////        months.forEach { month in
////            if let date = Calendar.current.date(from: month) {
////                viewModel.loadBookingRecords(for: date)
////            }
////        }
////    }
////    
////}
//
