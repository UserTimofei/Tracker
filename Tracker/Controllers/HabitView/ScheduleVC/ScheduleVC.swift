import UIKit

// MARK: - ScheduleVC
final class ScheduleVC: UIViewController {
    
    // MARK: - Properties
    var selectedDays: Set<WeekDay> = []
    var onSave: ((Set<WeekDay>) -> Void)?
    
    // MARK: - UI Elements
    private let tableViewContainer = UIView()
    private let tableView = UITableView()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .appBlack
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(
            NSLocalizedString("schedule.done.button", comment: "Done button"),
            for: .normal
        )
        button.setTitleColor(.appWhite, for: .normal)
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelNewHabit), for: .touchUpInside)
    
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupUI()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationItem() {
        navigationItem.hidesBackButton = true
    }
    
    private func setupUI() {
        setupTableView()
        
        title = NSLocalizedString("schedule.title", comment: "Schedule screen title")
        
        view.backgroundColor = .appWhite
        view.addSubview(tableViewContainer)
        view.addSubview(doneButton)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        tableViewContainer.addSubview(tableView)
        tableViewContainer.backgroundColor = .appBackground
        tableViewContainer.layer.cornerRadius = 16
        tableViewContainer.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            tableViewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableViewContainer.heightAnchor.constraint(equalToConstant: 525),
            
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 60),
            
            tableView.topAnchor.constraint(equalTo: tableViewContainer.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: tableViewContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: tableViewContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: tableViewContainer.trailingAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.backgroundColor = .appBackground
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: ScheduleCell.reuseIdentifier)
        tableView.separatorStyle = .none
    }
    
    // MARK: - Actions
    @objc private func cancelNewHabit() {
        print("📤 ScheduleVC: передаем выбранные дни: \(selectedDays.map { $0.rawValue })")
        onSave?(selectedDays)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ScheduleVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return WeekDay.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleCell.reuseIdentifier, for:  indexPath) as? ScheduleCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .appBackground
        let day = WeekDay.allCases[indexPath.row]
        let isLast = indexPath.row == WeekDay.allCases.count - 1
        cell.configure(with: day, isSelected: selectedDays.contains(day), onToggle: { [weak self] isOn in
                if isOn {
                    self?.selectedDays.insert(day)
                } else {
                    self?.selectedDays.remove(day)
                }
            }, isLast: isLast)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}
