//
//  ScheduleVC.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 03.02.2026.
//
import UIKit

class ScheduleVC: UIViewController {
    
    var selectedDays: Set<WeekDay> = []
    var onSave: ((Set<WeekDay>) -> Void)?
    
    private let tableViewContainer = UIView()
    private let tableView = UITableView()
    
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .appBlack
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.appWhite, for: .normal)
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelNewHabit), for: .touchUpInside)
    
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Расписание"
        view.backgroundColor = .appWhite
        navigationItem.hidesBackButton = true
        setupTableView()
        setupUI()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    private func setupUI() {
        view.backgroundColor = .appWhite
//        tableViewContainer.backgroundColor = .clear
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
//        tableView.separatorColor = .appGray
//        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    @objc private func cancelNewHabit() {
        onSave?(selectedDays)
        navigationController?.popViewController(animated: true)
    }
    
}

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

class ScheduleCell: UITableViewCell {
    static let reuseIdentifier = "ScheduleCell"
    
    private let separatorView = UIView()
    var onToggle: ((Bool) -> Void)?
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        title.textColor = .appBlack
        title.translatesAutoresizingMaskIntoConstraints = false
        
        return title
    }()
    
    private lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.onTintColor = .appBlue
        
        return switchControl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(switchControl)
        
        
        separatorView.backgroundColor = .appGray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant:  -16),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    func configure(with day: WeekDay, isSelected: Bool, onToggle: @escaping (Bool) -> Void, isLast: Bool = false) {
        titleLabel.text = day.title
        switchControl.isOn = isSelected
        self.onToggle = onToggle
        
        separatorView.isHidden = isLast
    }
    
    
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        onToggle?(sender.isOn)
    }
}
