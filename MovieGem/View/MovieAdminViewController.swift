import UIKit
import Combine

class MovieAdminViewController: UIViewController {
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    private var showtimes: [MovieShowtime] = []
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["影廳管理", "場次管理", "票價設定", "座位圖"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    // 影廳管理視圖
    private lazy var theaterManagementView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var theaterTableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TheaterCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private lazy var addTheaterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("新增影廳", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addTheaterTapped), for: .touchUpInside)
        return button
    }()
    
    // 場次管理視圖
    private lazy var showTimeManagementView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    
    
    private lazy var showTimeCalendar: UICalendarView = {
        let calendar = UICalendarView()
        calendar.calendar = .current
        calendar.locale = .current
        calendar.translatesAutoresizingMaskIntoConstraints = false
        
        // 設置日曆視圖的樣式
        let gregorianCalendar = Calendar(identifier: .gregorian)
        calendar.calendar = gregorianCalendar
        
        // 自定義日曆外觀
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        calendar.selectionBehavior = dateSelection
        
        return calendar
    }()
    
    
    private lazy var showTimeTableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "ShowTimeCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupInitialData()
        
        // 設置 table view
        showTimeTableView.dataSource = self
        showTimeTableView.delegate = self
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "後台管理系統"
        
        // 添加導航欄按鈕
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        
        // 添加主要視圖
        view.addSubview(segmentedControl)
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        
        // 添加子視圖
        containerView.addSubview(theaterManagementView)
        containerView.addSubview(showTimeManagementView)
        
        // 設置影廳管理視圖
        theaterManagementView.addSubview(theaterTableView)
        theaterManagementView.addSubview(addTheaterButton)
        
        // 設置場次管理視圖
        showTimeManagementView.addSubview(showTimeCalendar)
        showTimeManagementView.addSubview(showTimeTableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // SegmentedControl 約束
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // ScrollView 約束
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContainerView 約束
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 影廳管理視圖約束
            theaterManagementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            theaterManagementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            theaterManagementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            theaterManagementView.heightAnchor.constraint(equalToConstant: 600),
            
            theaterTableView.topAnchor.constraint(equalTo: theaterManagementView.topAnchor),
            theaterTableView.leadingAnchor.constraint(equalTo: theaterManagementView.leadingAnchor, constant: 16),
            theaterTableView.trailingAnchor.constraint(equalTo: theaterManagementView.trailingAnchor, constant: -16),
            theaterTableView.bottomAnchor.constraint(equalTo: addTheaterButton.topAnchor, constant: -16),
            
            addTheaterButton.leadingAnchor.constraint(equalTo: theaterManagementView.leadingAnchor, constant: 16),
            addTheaterButton.trailingAnchor.constraint(equalTo: theaterManagementView.trailingAnchor, constant: -16),
            addTheaterButton.bottomAnchor.constraint(equalTo: theaterManagementView.bottomAnchor, constant: -16),
            addTheaterButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 場次管理視圖約束
            showTimeManagementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            showTimeManagementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            showTimeManagementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            showTimeManagementView.heightAnchor.constraint(equalToConstant: 800),
            
            showTimeCalendar.topAnchor.constraint(equalTo: showTimeManagementView.topAnchor),
            showTimeCalendar.leadingAnchor.constraint(equalTo: showTimeManagementView.leadingAnchor, constant: 16),
            showTimeCalendar.trailingAnchor.constraint(equalTo: showTimeManagementView.trailingAnchor, constant: -16),
            showTimeCalendar.heightAnchor.constraint(equalToConstant: 300),
            
            showTimeTableView.topAnchor.constraint(equalTo: showTimeCalendar.bottomAnchor, constant: 16),
            showTimeTableView.leadingAnchor.constraint(equalTo: showTimeManagementView.leadingAnchor, constant: 16),
            showTimeTableView.trailingAnchor.constraint(equalTo: showTimeManagementView.trailingAnchor, constant: -16),
            showTimeTableView.bottomAnchor.constraint(equalTo: showTimeManagementView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: // 影廳管理
            theaterManagementView.isHidden = false
            showTimeManagementView.isHidden = true
            goToTheaterManagement()
        case 1: // 場次管理
            theaterManagementView.isHidden = true
            showTimeManagementView.isHidden = false
            goToShowtimeManagement()
        case 2: // 票價設定
            goToPriceManagement()
        case 3: // 座位圖
            goToTheaterDetail()
        default:
            break
        }
    }
    
    // 添加新的導航方法
    @objc func goToTheaterManagement() {
        let theaterManagementVC = TheaterManagementViewController()
        navigationController?.pushViewController(theaterManagementVC, animated: true)
    }
    
    @objc func goToShowtimeManagement() {
        let showtimeManagementVC = ShowtimeManagementViewController()
        navigationController?.pushViewController(showtimeManagementVC, animated: true)
    }
    
    @objc func goToPriceManagement() {
        let priceManagementVC = PriceManagementViewController()
        navigationController?.pushViewController(priceManagementVC, animated: true)
    }
    
    @objc func goToTheaterDetail() {
        // 創建 GoogleSheetsService
        let sheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)
        
        // 創建 ViewModel
        let movieSheetViewModel = MovieSheetViewModel(sheetsService: sheetsService)
        
        // 創建默認的 Theater 實例
        let defaultTheater = Theater(
            id: UUID().uuidString,
            name: "預設影廳",
            capacity: 100,
            type: .standard,
            status: .active,
            seatLayout: [[.normal, .normal, .normal],
                         [.normal, .vip, .normal],
                         [.normal, .normal, .normal]]
        )
        
        // 創建 TheaterDetailViewController
        let theaterDetailVC = TheaterDetailViewController(theater: defaultTheater, viewModel: movieSheetViewModel)
        
        navigationController?.pushViewController(theaterDetailVC, animated: true)
    }
    

    
    @objc private func addTheaterTapped() {
        let alert = UIAlertController(title: "新增影廳",
                                      message: "請輸入影廳資訊",
                                      preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "影廳名稱"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "座位數量"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            // TODO: 處理新增影廳邏輯
        })
        
        present(alert, animated: true)
    }
    
    @objc private func settingsTapped() {
        let alert = UIAlertController(title: "設定",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "系統設定", style: .default))
        alert.addAction(UIAlertAction(title: "使用者管理", style: .default))
        alert.addAction(UIAlertAction(title: "操作紀錄", style: .default))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Data Setup
    private func setupInitialData() {
        // 加載場次數據
        loadShowtimes()
    }
    
    private func loadShowtimes() {
        // 假設您有一個獲取場次的服務
        Task {
            do {
                // 這裡使用您的場次服務獲取數據
                // showtimes = try await showtimeService.fetchShowtimes()
                
                // 更新 showTimeTableView
                DispatchQueue.main.async {
                    self.showTimeTableView.reloadData()
                }
            } catch {
                print("載入場次數據失敗: \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toMovieSheet":
            if let destination = segue.destination as? MovieSheetViewController {
                // 傳遞必要的資料
            }
        case "toTheaterManagement":
            if let destination = segue.destination as? TheaterManagementViewController {
                // 傳遞必要的資料
            }
            // 其他Case
        default:
            break
        }
    }
    
    @objc func someButtonTapped() {
        goToMovieSheet()
    }
    
    
    @objc func goToMovieSheet() {
        do {
            let sheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)
            let movieSheetViewModel = MovieSheetViewModel(sheetsService: sheetsService)
            let movieSheetVC = MovieSheetViewController(viewModel: movieSheetViewModel)
            
            guard let navigationController = self.navigationController else {
                print("❌ Navigation Controller is nil")
                return
            }
            
            navigationController.pushViewController(movieSheetVC, animated: true)
        } catch {
            print("❌ Error navigating to MovieSheetViewController: \(error)")
        }
    }
    
}

// 實現 UITableViewDataSource
extension MovieAdminViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showtimes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShowTimeCell", for: indexPath)
        let showtime = showtimes[indexPath.row]
        
        // 配置 cell
        cell.textLabel?.text = "場次: \(showtime.startTime)"
        
        return cell
    }
}

extension MovieAdminViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        // 處理日期選擇事件
        guard let selectedDate = dateComponents?.date else { return }
        print("選擇的日期: \(selectedDate)")
        
        // 可以在這裡更新場次表格或執行其他邏輯
    }
}
