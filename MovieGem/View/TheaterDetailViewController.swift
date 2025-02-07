import UIKit

class TheaterDetailViewController: UIViewController {
    private let theater: Theater
    private let viewModel: TheaterDetailViewModel
    private var movies: [MovieSheetData] = []
    
    // UI 元件
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TheaterDetailCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private lazy var theaterInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(theater: Theater, sheetsService: MovieBookingDataService) {
        self.theater = theater  // 先初始化 theater
        self.viewModel = TheaterDetailViewModel(theater: theater, sheetsService: sheetsService)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func configureTheaterInfo() {
        // 直接使用 ViewModel 的屬性
        theaterInfoLabel.text = viewModel.theaterInfo
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "\(theater.name) - 詳細資訊"
        
        setupUI()
        setupConstraints()
        configureTheaterInfo()
        fetchMovieData()
    }
    
    private func setupUI() {
        view.addSubview(theaterInfoLabel)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            theaterInfoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            theaterInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            theaterInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: theaterInfoLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchMovieData() {
        viewModel.fetchMovieData()
        
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &viewModel.cancellables)
    }
    
}

// MARK: - UITableViewDataSource & Delegate
extension TheaterDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.movies.count  // 直接使用 viewModel.movies
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TheaterDetailCell", for: indexPath)
        let movie = viewModel.movies[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = viewModel.getMovieCellText(movie)
        return cell
    }

    
}
