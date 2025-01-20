import UIKit
import Combine

class MovieSheetViewController: UIViewController {
    private let viewModel: MovieSheetViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(MovieTicketCell.self, forCellReuseIdentifier: MovieTicketCell.identifier)
        table.delegate = self
        table.dataSource = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    init(viewModel: MovieSheetViewModel = MovieSheetViewModel(sheetsService: GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint))) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let service = GoogleSheetsService(apiEndpoint: SheetDBConfig.apiEndpoint)
        self.viewModel = MovieSheetViewModel(sheetsService: service)
        super.init(coder: coder)
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 只在資料為空時才重新加載
        if viewModel.movies.isEmpty {
            viewModel.fetchMovieData()
        }
    }


    

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNotifications()
        title = "訂票紀錄"
        viewModel.fetchMovieData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                // 只在資料不為空時重新加載表格
                if !movies.isEmpty {
                    self?.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.tableView.isHidden = true
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.tableView.isHidden = false
                }
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showError(error)
                }
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
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDateChange),
            name: Notification.Name("SelectedDateChanged"),
            object: nil
        )
    }
    
    @objc private func handleDateChange(_ notification: Notification) {
        guard let date = notification.userInfo?["selectedDate"] as? Date else { return }
        filterMoviesByDate(date)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func filterMoviesByDate(_ date: Date) {
        let calendar = Calendar.current
        let filteredMovies = viewModel.movies.filter { movie in
            guard let movieDate = movie.date else { return false }
            return calendar.isDate(movieDate, inSameDayAs: date)
        }
        // 更新顯示
        viewModel.movies = filteredMovies
    }
    
}

// MARK: - UITableViewDataSource & Delegate
extension MovieSheetViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MovieTicketCell.identifier, for: indexPath) as? MovieTicketCell else {
            return UITableViewCell()
        }
        
        let movie = viewModel.movies[indexPath.row]
        cell.configure(with: movie)  // 移除重複的 print 語句
        return cell
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.movies.count
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

