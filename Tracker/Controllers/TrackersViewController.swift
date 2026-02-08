//
//  ViewController.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 13.01.2026.
//

import UIKit



class TrackersViewController: UIViewController, UICollectionViewDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        searchService.filterCategories(searchText: searchText)
    }
    
    
    // MARK: - Properties
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    
    private var currentDate = Date()
    
    private let searchService = SearchService()
    
    private lazy var collectionView: UICollectionView = {
        let layout = TrackersViewController.createLayout()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        return collectionView
    }()
    
    private let placeholderView: UIView = {
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let starImage = UIImageView(image: .appError)
        starImage.tintColor = .appGray
        starImage.contentMode = .scaleAspectFit
        starImage.widthAnchor.constraint(equalToConstant: 80).isActive = true
        starImage.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let labelTextError = UILabel()
        labelTextError.translatesAutoresizingMaskIntoConstraints = false
        labelTextError.text = "Что будем отслеживать?"
        labelTextError.numberOfLines = 1
        labelTextError.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        labelTextError.textColor = .appBlack
        labelTextError.textAlignment = .center
        labelTextError.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        labelTextError.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let textSize = labelTextError.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20))
        labelTextError.widthAnchor.constraint(greaterThanOrEqualToConstant: textSize.width).isActive = true
        
        stack.addArrangedSubview(starImage)
        stack.addArrangedSubview(labelTextError)
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16)
        ])
        return container
    }()
       
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTestData()
        setupUI()
        
        collectionView.register(TrackerCategoryHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrackerCategoryHeader.reuseIdentifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        updatePlaceholderVisibility()
    }
    
    private func setupTestData() {
        let testTrackers = [
            Tracker(
                id: UUID(),
                name: "Пить воду",
                color: .systemBlue,
                emoji: "💧",
                schedule: [.monday, .sunday, .tuesday, .friday, .saturday, .sunday, .wednesday]
            ),
            Tracker(
                id: UUID(),
                name: "Спорт",
                color: .systemGreen,
                emoji: "🏃‍♂️",
                schedule: [.tuesday, .sunday]
            )
        ]
        let testTrackers2 = [
            Tracker(
                id: UUID(),
                name: "Пить воду",
                color: .appRed,
                emoji: "💧",
                schedule: [.monday, .sunday, .tuesday, .friday, .saturday, .sunday, .wednesday]
            ),
            Tracker(
                id: UUID(),
                name: "Спорт",
                color: .appColorSelection1,
                emoji: "🏃‍♂️",
                schedule: [.tuesday, .sunday]
            )
        ]
        
        
        
        categories = [
            TrackerCategory(header: "Полезные привычки", trackers: testTrackers),
            TrackerCategory(header: "Неполезные привычки", trackers: testTrackers2)
        ]
        visibleCategories = categories
    }
    
    private static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .absolute(148)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(148)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: 2
            )
            group.interItemSpacing = .fixed(8)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(30)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            section.contentInsets = NSDirectionalEdgeInsets(
                top: 4,
                leading: 12,
                bottom: 16,
                trailing: 12
            )

            return section
        }
        return layout
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .appWhite
        
        view.addSubview(placeholderView)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        ])
        
    }
    
    private func setupNavigationBar() {
        let plusButton = UIButton(type: .system)
        plusButton.setImage(.plusDark, for: .normal)
        plusButton.tintColor = .appBlack
        plusButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: plusButton)
        
        navigationController?.navigationBar.tintColor = .appBlack
        
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.hidesNavigationBarDuringPresentation = false
        search.automaticallyShowsCancelButton = true
        search.searchBar.placeholder = "Поиск"
        navigationItem.searchController = search
        definesPresentationContext = true
        search.searchBar.delegate = self
        
        
        navigationItem.title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    

        let datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        datePicker.calendar.firstWeekday = 2
        
        datePicker.date = currentDate
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .year, value: -10, to: currentDate)
        let maxDate = calendar.date(byAdding: .year, value: 10, to: currentDate)
        datePicker.minimumDate = minDate
        datePicker.maximumDate = maxDate
        

    }
    
    // MARK: - Actions

    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        // Сохраняем выбранную дату (без времени!)
        currentDate = Calendar.current.startOfDay(for: sender.date)
        
        // Обновляем UI
        collectionView.reloadData()
        updatePlaceholderVisibility()
        
        // Для отладки (можно удалить)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        print("Выбрана дата: \(formatter.string(from: currentDate))")
    }
    
    @objc private func addButtonTapped() {
        
        let newHabitVC = NewHabitViewController()
        newHabitVC.onSave = { [weak self] tracker in
            self?.addTracker(tracker, toCategoryAtIndex: "Полезные привычки")
        }
        let navController = UINavigationController(rootViewController: newHabitVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
        
    private func isCompleted(trackerId: UUID, on date: Date) -> Bool {
        let targetDay = Calendar.current.startOfDay(for: date)
            return completedTrackers.contains { record in
                record.trackerId == trackerId &&
                Calendar.current.isDate(record.date, inSameDayAs: targetDay)
            }
    }

    private func addTracker(_ newTracker: Tracker, toCategoryAtIndex categoryTitle: String) {
        let updateCategory = categories.map { category in
            if category.header == categoryTitle {
                return TrackerCategory(
                    header: category.header,
                    trackers: category.trackers + [newTracker]
                )
            }
            
            return category
            
        }
        
        categories = updateCategory
        visibleCategories = updateCategory
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }
    
    private func getVisibleCategories() -> [TrackerCategory] {

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        
        return visibleCategories.compactMap { category in
            let trackersForToday = category.trackers.filter { tracker in
                tracker.schedule.contains { $0.calendarWeekDay == weekday }
            }
            return trackersForToday.isEmpty ? nil : TrackerCategory(
                header: category.header,
                trackers: trackersForToday
            )
        }
    }
  
    private func updatePlaceholderVisibility() {
        placeholderView.isHidden = !getVisibleCategories().isEmpty
    }

}

extension TrackersViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Unexpected element kind: \(kind)")
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackerCategoryHeader.reuseIdentifier, for: indexPath)  as? TrackerCategoryHeader ?? TrackerCategoryHeader()
        
        let category = getVisibleCategories()[indexPath.section]
        header.configure(with: category.header)
        return header
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return getVisibleCategories().count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let visibleCategories = getVisibleCategories()
        guard section < visibleCategories.count else { return 0 }
        
        let category = visibleCategories[section]
        let trackersForToday = getTrackersForToday(in: category)
        return trackersForToday.count
                                                    
                                                    
    }
    
    private func getTrackersForToday(in category: TrackerCategory) -> [Tracker] {
        let weekday = Calendar.current.component(.weekday, from: currentDate)
        return category.trackers.filter {
            $0.schedule.contains { $0.calendarWeekDay == weekday }
        }
    }
    
    private func isFutureDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let selectedDateStart = calendar.startOfDay(for: date)
        return selectedDateStart > todayStart
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.reuseIdentifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let visibleCategories = getVisibleCategories()
        guard indexPath.section < visibleCategories.count else { return cell }
        
        let category = visibleCategories[indexPath.section]
        let trackersForToday = getTrackersForToday(in: category)
        guard indexPath.item < trackersForToday.count else { return cell }
        
        let tracker = trackersForToday[indexPath.item]
        
        let completionCount = completedTrackers.count { $0.trackerId == tracker.id}

        let isCompleted = self.isCompleted(trackerId: tracker.id, on: currentDate)
        
        let isFuture = isFutureDate(currentDate)
        
        cell.isUserInteractionEnabled = !isFuture
        
        cell.contentView.alpha = 1.0
        
        if isFuture {
            cell.contentView.alpha = 0.5
            cell.isUserInteractionEnabled = false
        } else {
            cell.isUserInteractionEnabled = true
        }
        
        cell.configure(
                    with: tracker,
                    isCompleted: isCompleted,
                    isFutureDate:isFuture,
                    numbersOfCompletedTrackers: completionCount
                ) { [weak self] isCompletedInCel in
                    guard let self = self else { return }
                    
                    let today  = Calendar.current.startOfDay(for: self.currentDate)
                    
                    let record = TrackerRecord(trackerId: tracker.id, date: today)
                    
                    if isCompletedInCel {
                        self.completedTrackers.insert(record)
                    } else {
                        self.completedTrackers.remove(record)
                    }
                    collectionView.reloadItems(at: [indexPath])
                }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let spacing: CGFloat = 12
        let availableWidth = view.frame.width - padding * 2 - spacing
        let width = availableWidth / 2
        return CGSize(width: width, height: 112)
    }
}

//extension TrackerViewController: UICollectionViewDelegateFlowLayout {
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        layout collectionViewLayout: UICollectionViewLayout,
//        sizeForItemAt indexPath: IndexPath
//    ) -> CGSize {
//
//        let width = (collectionView.bounds.width - 16 * 2 - 8) / 2
//        return CGSize(width: width, height: 148)
//    }
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        layout collectionViewLayout: UICollectionViewLayout,
//        referenceSizeForHeaderInSection section: Int
//    ) -> CGSize {
//
//        CGSize(width: collectionView.bounds.width, height: 18)
//    }
//}

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchService.filterCategories(searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
            // Сбросьте фильтрацию
            visibleCategories = categories
            collectionView.reloadData()
            updatePlaceholderVisibility()
            searchBar.resignFirstResponder()
        }
}


//#Preview {
//    let vc = TabBarController()
//    return vc
//
//}
