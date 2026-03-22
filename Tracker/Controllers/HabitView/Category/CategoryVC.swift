
import UIKit

final class CategoryViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: CategoryViewModel
    var onCategorySelected: ((String) -> Void)?
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 75
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.layer.cornerRadius = 16
        tableView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tableView.clipsToBounds = true
        
        return tableView
    }()
    
    private lazy var tableViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var placeholderView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let starImage = UIImageView(image: .appError)
        starImage.tintColor = .appGray
        starImage.contentMode = .scaleAspectFit
        starImage.widthAnchor.constraint(equalToConstant: 80).isActive = true
        starImage.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .appBlack
        label.textAlignment = .center
        
        stack.addArrangedSubview(starImage)
        stack.addArrangedSubview(label)
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
        button.backgroundColor = .appBlack
        button.setTitleColor(.appWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    init(selectedCategory: String? = nil) {
        self.viewModel = CategoryViewModel(selectedCategoryTitle: selectedCategory)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.loadCategories()
        
        navigationItem.hidesBackButton = true
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Категория"
        view.backgroundColor = .appWhite
        
        view.addSubview(tableView)
        view.addSubview(placeholderView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch state {
                case .loaded:
                    self.tableView.reloadData()
                    self.placeholderView.isHidden = true
                    
                case .empty:
                    self.tableView.reloadData()
                    self.placeholderView.isHidden = false
                    
                case .categoryAdded(let index):
                    self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.placeholderView.isHidden = true
                    
                case .categoryDeleted(let index):
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    if self.viewModel.numberOfCategories == 0 {
                        self.placeholderView.isHidden = false
                    }
                    
                case .categoryUpdated(let index):
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    
                case .selectionChanged(let index):
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    
                case .error(let message):
                    self.showErrorAlert(message)
                    
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let newCategoryVC = NewCategoryViewController()
        newCategoryVC.onCategoryCreated = { [weak self] categoryName in
            self?.viewModel.createCategory(title: categoryName)
        }
        navigationController?.pushViewController(newCategoryVC, animated: true)
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showEditCategoryScreen(at index: Int) {
        guard let oldTitle = viewModel.categoryTitle(at: index) else { return }
        
        let editCategoryVC = EditCategoryViewController(oldCategoryName: oldTitle)
        editCategoryVC.onCategoryEdited = { [weak self] oldName, newName in
            self?.viewModel.updateCategory(oldTitle: oldName, newTitle: newName)
        }
        navigationController?.pushViewController(editCategoryVC, animated: true)
    }
    
    private func showDeleteConfirmation(at index: Int) {
        let alertController = UIAlertController(
            title: "Удалить категорию?",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: index)
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension CategoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCategories
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let title = viewModel.categoryTitle(at: indexPath.row) ?? ""
        let isSelected = viewModel.isCategorySelected(at: indexPath.row)
        
        print("📝 Ячейка: \(title), выбрана: \(isSelected)")
        
        let isLast = indexPath.row == viewModel.numberOfCategories - 1
        
        cell.configure(with: title, isSelected: isSelected, isLast: isLast)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectCategory(at: indexPath.row)
        if let selectedCategory = viewModel.category(at: indexPath.row) {
            onCategorySelected?(selectedCategory.header)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { _ in
            let editAction = UIAction(
                title: "Редактировать",
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                self?.showEditCategoryScreen(at: indexPath.row)
            }
            
            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.showDeleteConfirmation(at: indexPath.row)
            }
            
            return UIMenu(children: [editAction, deleteAction])
        })
    }
}
