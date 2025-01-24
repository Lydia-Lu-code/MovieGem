import UIKit
import Combine

protocol MovieAdminViewModelProtocol: ObservableObject {
    func loadData()
}

class MovieAdminViewController: UIViewController {
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentIndex: Int = 0
    
    // MARK: - UI Components
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
        let sheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)
        let viewModel = MovieSheetViewModel(sheetsService: sheetsService)
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
    
    // MARK: - Lifecycle
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
    
    
    
    // MARK: - UI Setup
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
    
    private func showAddTheaterAlert() {
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
                
                self?.theaterViewController.viewModel.addTheater(name: name, capacity: capacity, type: type)
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

    private func showAddMovieSheetAlert() {
        // 實作新增訂票邏輯
    }

    private func showAddShowtimeAlert() {
        // 實作新增場次邏輯
    }

    private func showAddPriceAlert() {
        // 實作新增票價邏輯
    }
    
    // MARK: - Actions
    
    @objc private func performPrimaryAction() {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // 影廳管理
            showAddTheaterAlert()
        case 1: // 訂票紀錄
            showAddMovieSheetAlert()
        case 2: // 場次管理
            showAddShowtimeAlert()
        case 3: // 票價設定
            showAddPriceAlert()
        default:
            break
        }
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
        
        // 更新 actionButton 標題
        updateActionButton(for: sender.selectedSegmentIndex)
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


//import UIKit
//import Combine
//
//protocol MovieAdminViewModelProtocol: ObservableObject {
//    func loadData()
//}
//
//class MovieAdminViewController: UIViewController {
//    // MARK: - Properties
//    private var cancellables = Set<AnyCancellable>()
//    private var currentIndex: Int = 0
//    
//    // MARK: - UI Components
//    private lazy var segmentedControl: UISegmentedControl = {
//        let items = ["影廳管理", "訂票紀錄", "場次管理", "票價設定"]
//        let control = UISegmentedControl(items: items)
//        control.selectedSegmentIndex = 0
//        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
//        control.translatesAutoresizingMaskIntoConstraints = false
//        return control
//    }()
//    
//    private lazy var containerView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private lazy var actionButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("操作", for: .normal)
//        button.backgroundColor = .systemBlue
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 8
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    // 子視圖控制器
//    private lazy var theaterViewController: TheaterManagementViewController = {
//        let viewModel = TheaterManagementViewModel()
//        let vc = TheaterManagementViewController(viewModel: viewModel)
//        return vc
//    }()
//    
//    private lazy var movieSheetViewController: MovieSheetViewController = {
//        let sheetsService = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)
//        let viewModel = MovieSheetViewModel(sheetsService: sheetsService)
//        let vc = MovieSheetViewController(viewModel: viewModel)
//        return vc
//    }()
//    
//    private lazy var showtimeViewController: ShowtimeManagementViewController = {
//        let viewModel = ShowtimeManagementViewModel()
//        let vc = ShowtimeManagementViewController(viewModel: viewModel)
//        return vc
//    }()
//    
//    private lazy var priceViewController: PriceManagementViewController = {
//        let viewModel = PriceManagementViewModel()
//        let vc = PriceManagementViewController(viewModel: viewModel)
//        return vc
//    }()
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupConstraints()
//        setupChildViewControllers()
//        
//        // 預設載入第一個視圖的資料
//        let viewControllers = [
//            theaterViewController,
//            movieSheetViewController,
//            showtimeViewController,
//            priceViewController
//        ]
//        
//        // 載入第一個視圖（影廳管理）的資料
//        viewControllers[0].view.frame = containerView.bounds
//        viewControllers[0].view.isHidden = false
//        theaterViewController.viewModel.loadData()
//        
//        // 設置 actionButton
//        actionButton.setTitle("新增影廳", for: .normal)
//        actionButton.addTarget(self, action: #selector(performPrimaryAction), for: .touchUpInside)
//
//    }
//    
//    
//    
//    // MARK: - UI Setup
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        title = "後台管理系統"
//        
//        view.addSubview(segmentedControl)
//        view.addSubview(containerView)
//        view.addSubview(actionButton)
//    }
//    
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            
//            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            containerView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -16),
//            
//            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            actionButton.heightAnchor.constraint(equalToConstant: 44)
//        ])
//    }
//    
//    private func setupChildViewControllers() {
//        let viewControllers = [
//            theaterViewController,
//            movieSheetViewController,
//            showtimeViewController,
//            priceViewController
//        ]
//        
//        viewControllers.forEach { childVC in
//            addChild(childVC)
//            containerView.addSubview(childVC.view)
//            childVC.view.frame = containerView.bounds
//            childVC.didMove(toParent: self)
//            childVC.view.isHidden = true
//        }
//        
//        // 預設顯示第一個
//        viewControllers[0].view.isHidden = false
//    }
//    
//    private func showAddTheaterAlert() {
//        let alert = UIAlertController(title: "新增影廳", message: nil, preferredStyle: .alert)
//        
//        alert.addTextField { textField in
//            textField.placeholder = "影廳名稱"
//        }
//        
//        alert.addTextField { textField in
//            textField.placeholder = "座位容量"
//            textField.keyboardType = .numberPad
//        }
//        
//        let pickerVC = UIAlertController(title: "選擇影廳類型", message: nil, preferredStyle: .actionSheet)
//        Theater.TheaterType.allCases.forEach { type in
//            let action = UIAlertAction(title: type.rawValue, style: .default) { [weak self] _ in
//                guard let name = alert.textFields?[0].text,
//                      let capacityText = alert.textFields?[1].text,
//                      let capacity = Int(capacityText) else { return }
//                
//                self?.theaterViewController.viewModel.addTheater(name: name, capacity: capacity, type: type)
//            }
//            pickerVC.addAction(action)
//        }
//        
//        pickerVC.addAction(UIAlertAction(title: "取消", style: .cancel))
//        
//        alert.addAction(UIAlertAction(title: "下一步", style: .default) { [weak self] _ in
//            self?.present(pickerVC, animated: true)
//        })
//        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
//        
//        present(alert, animated: true)
//    }
//
//    private func showAddMovieSheetAlert() {
//        // 實作新增訂票邏輯
//    }
//
//    private func showAddShowtimeAlert() {
//        // 實作新增場次邏輯
//    }
//
//    private func showAddPriceAlert() {
//        // 實作新增票價邏輯
//    }
//    
//    // MARK: - Actions
//    
//    @objc private func performPrimaryAction() {
//        switch segmentedControl.selectedSegmentIndex {
//        case 0: // 影廳管理
//            showAddTheaterAlert()
//        case 1: // 訂票紀錄
//            showAddMovieSheetAlert()
//        case 2: // 場次管理
//            showAddShowtimeAlert()
//        case 3: // 票價設定
//            showAddPriceAlert()
//        default:
//            break
//        }
//    }
//    
//    
//    
//    @objc private func segmentChanged(_ sender: UISegmentedControl) {
//        let viewControllers = [
//            theaterViewController,
//            movieSheetViewController,
//            showtimeViewController,
//            priceViewController
//        ]
//        
//        // 隱藏所有子視圖
//        viewControllers.forEach { $0.view.isHidden = true }
//        
//        // 顯示當前選擇的子視圖
//        let selectedVC = viewControllers[sender.selectedSegmentIndex]
//        selectedVC.view.isHidden = false
//        
//        // 更新 actionButton 標題
//        updateActionButton(for: sender.selectedSegmentIndex)
//    }
//    
//    private func updateActionButton(for index: Int) {
//        switch index {
//        case 0:
//            actionButton.setTitle("新增影廳", for: .normal)
//        case 1:
//            actionButton.setTitle("新增訂票", for: .normal)
//        case 2:
//            actionButton.setTitle("新增場次", for: .normal)
//        case 3:
//            actionButton.setTitle("新增票價", for: .normal)
//        default:
//            break
//        }
//    }
//}
//
