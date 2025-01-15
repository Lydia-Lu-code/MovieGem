import UIKit

class TheaterDetailViewController: UIViewController {
    private let theater: Theater
    private let viewModel: MovieSheetViewModel
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
    
    init(theater: Theater, viewModel: MovieSheetViewModel) {
        self.theater = theater
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    private func configureTheaterInfo() {
        theaterInfoLabel.text = """
        影廳名稱: \(theater.name)
        座位數: \(theater.capacity)
        類型: \(theater.type.rawValue)
        狀態: \(theater.status.rawValue)
        """
    }
    
    private func fetchMovieData() {
        // 使用現有的 ViewModel 獲取電影資料
        viewModel.fetchMovieData()
        
        // 監聽數據變化
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.movies = movies
                self?.tableView.reloadData()
            }
            .store(in: &viewModel.cancellables)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TheaterDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TheaterDetailCell", for: indexPath)
        let movie = movies[indexPath.row]
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = """
        電影: \(movie.movieName)
        日期: \(movie.showDate)
        時間: \(movie.showTime)
        座位: \(movie.seats)
        """
        
        return cell
    }
}
