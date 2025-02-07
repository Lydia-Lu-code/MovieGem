import UIKit
import Combine

protocol MovieAdminViewModelProtocol: ObservableObject {
    func loadData()
}

class MovieAdminViewController: UIViewController {
    // MARK: - 屬性
    private var cancellables = Set<AnyCancellable>()
    private var currentIndex: Int = 0
    private var isShowingAlert = false
    
    // MARK: - 使用者介面元件
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["影廳管理", "訂票紀錄", "場次管理", "票價設定"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("操作", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 子視圖控制器
    private lazy var theaterViewController: TheaterManagementViewController = {
        let viewModel = TheaterManagementViewModel()
        let vc = TheaterManagementViewController(viewModel: viewModel)
        return vc
    }()
    
    private lazy var movieSheetViewController: MovieSheetViewController = {
        let sheetsService = GoogleSheetsService()
        let viewModel = MovieSheetViewModel(sheetsService: sheetsService as! MovieBookingDataService)
        let vc = MovieSheetViewController(viewModel: viewModel)
        return vc
    }()
    
    private lazy var showtimeViewController: ShowtimeManagementViewController = {
        let viewModel = ShowtimeManagementViewModel()
        let vc = ShowtimeManagementViewController(viewModel: viewModel)
        return vc
    }()
    
    private lazy var priceViewController: PriceManagementViewController = {
        let viewModel = PriceManagementViewModel()
        let vc = PriceManagementViewController(viewModel: viewModel)
        return vc
    }()
    
    // MARK: - 生命週期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupChildViewControllers()
        
        // 預設載入第一個視圖的資料
        let viewControllers = [
            theaterViewController,
            movieSheetViewController,
            showtimeViewController,
            priceViewController
        ]
        
        // 載入第一個視圖（影廳管理）的資料
        viewControllers[0].view.frame = containerView.bounds
        viewControllers[0].view.isHidden = false
        theaterViewController.viewModel.loadData()
        
        // 設置 actionButton
        actionButton.setTitle("新增影廳", for: .normal)
        actionButton.addTarget(self, action: #selector(performPrimaryAction), for: .touchUpInside)
    }
    
    // MARK: - 使用者介面設定
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "後台管理系統"
        
        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        view.addSubview(actionButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -16),
            
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            actionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        let viewControllers = [
            theaterViewController,
            movieSheetViewController,
            showtimeViewController,
            priceViewController
        ]
        
        // 隱藏所有子視圖
        viewControllers.forEach { $0.view.isHidden = true }
        
        // 顯示當前選擇的子視圖
        let selectedVC = viewControllers[sender.selectedSegmentIndex]
        selectedVC.view.isHidden = false
        
        // 如果選擇了訂票紀錄標籤，執行數據加載
        if sender.selectedSegmentIndex == 1 {
            // 使用當前日期，格式為 "yyyy-MM-dd"
            let currentDateString = DateFormatter.currentDateFormatter.string(from: Date())
            fetchMovieData(for: currentDateString)
        }
        
        // 更新 actionButton 標題
        updateActionButton(for: sender.selectedSegmentIndex)
    }
    
    private func fetchMovieData(for date: String) {
        guard !movieSheetViewController.viewModel.isLoading else { return }
        
        movieSheetViewController.viewModel.isLoading = true
        movieSheetViewController.viewModel.error = nil
        
        Task {
            do {
                // 使用正確的方法獲取數據
                let records = try await movieSheetViewController.viewModel.sheetsService.fetchMovieBookings()
                
                print("已獲取資料數量：\(records.count)")
                print("篩選日期：\(date)")
                
                await MainActor.run {
                    if records.isEmpty {
                        // 連結成功但無資料
                        movieSheetViewController.viewModel.error = NSError(
                            domain: "DataError",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "沒有訂位"]
                        )
                    } else {
                        // 有資料，正常處理
                        movieSheetViewController.viewModel.movies = records.map { record in
                            MovieSheetData(
                                bookingDate: record.date,
                                movieName: record.movieName,
                                showDate: record.showDate,
                                showTime: record.showTime,
                                numberOfPeople: record.numberOfTickets,
                                ticketType: record.ticketType,
                                seats: record.seats,
                                totalAmount: record.totalAmount
                            )
                        }
                        
                        // reloadData 移到這裡
                        if let tableView = movieSheetViewController.view.subviews.first(where: { $0 is UITableView }) as? UITableView {
                            tableView.reloadData()
                        }
                    }
                    
                    movieSheetViewController.viewModel.isLoading = false
                    
                    // 延遲檢查載入狀態
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.showAlert()
                    }
                }
            } catch {
                await MainActor.run {
                    // 無法連結到資料源
                    print("載入錯誤：\(error)")
                    
                    // 確保錯誤訊息是 "加載失敗"
                    movieSheetViewController.viewModel.error = NSError(
                        domain: "ConnectionError",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "加載失敗"]
                    )
                    movieSheetViewController.viewModel.isLoading = false
                    
                    // 延遲檢查載入狀態
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.showAlert()
                    }
                }
            }
        }
    }

    private func showAlert() {
        guard !isShowingAlert else { return }
        
        // 檢查 MovieSheetViewController 的 ViewModel 狀態
        if let error = movieSheetViewController.viewModel.error {
            // 判斷錯誤類型
            let errorMessage = (error as NSError).domain == "DataError" ? "沒有訂位" : "加載失敗"
            
            // 如果有錯誤，始終顯示對應的提示
            isShowingAlert = true
            
            let alert = UIAlertController(
                title: "提示",
                message: errorMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
                self?.isShowingAlert = false
            })
            
            present(alert, animated: true)
        }
        // 正常載入不顯示 alert
    }
    
    private func setupChildViewControllers() {
        let viewControllers = [
            theaterViewController,
            movieSheetViewController,
            showtimeViewController,
            priceViewController
        ]
        
        viewControllers.forEach { childVC in
            addChild(childVC)
            containerView.addSubview(childVC.view)
            childVC.view.frame = containerView.bounds
            childVC.didMove(toParent: self)
            childVC.view.isHidden = true
        }
        
        // 預設顯示第一個
        viewControllers[0].view.isHidden = false
    }
    
    // MARK: - 動作方法
    @objc private func performPrimaryAction() {
        // 這裡可以在未來實作新增邏輯
        print("主要動作按鈕被觸發，當前分頁：\(segmentedControl.selectedSegmentIndex)")
    }
    
    private func updateActionButton(for index: Int) {
        switch index {
        case 0:
            actionButton.setTitle("新增影廳", for: .normal)
        case 1:
            actionButton.setTitle("新增訂票", for: .normal)
        case 2:
            actionButton.setTitle("新增場次", for: .normal)
        case 3:
            actionButton.setTitle("新增票價", for: .normal)
        default:
            break
        }
    }
}


// 在 Date 擴展中添加一個新的日期格式化器
extension DateFormatter {
    static let currentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

