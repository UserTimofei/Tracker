//
//  ViewController.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 13.01.2026.
//

import UIKit
import CoreData

class TrackersViewController: UIViewController, UICollectionViewDelegate, UISearchResultsUpdating, SearchServiceDelegate, StoreDelegate {
    func didUpdate() {
        loadInitialData()
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }
    
    func didUpdateSearchResults(_ filteredCategories: [TrackerCategory]) {
        visibleCategories = filteredCategories
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        searchService.filterCategories(searchText: searchText)
    }
    // MARK: - Properties
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    
    private var currentDate = Date()
    private var currentWeekday: Int {
        return Calendar.current.component(.weekday, from: currentDate)
    }

    private let context: NSManagedObjectContext

    private let trackerStore: TrackerStore
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore

    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        self.trackerStore = TrackerStore(context: context)
        self.categoryStore = TrackerCategoryStore(context: context)
        self.recordStore = TrackerRecordStore(context: context)
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
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
        setupDelegates()
        
        
        do {
                categories = try categoryStore.fetchAllCategories()
                print("🔍 При запуске загружено категорий: \(categories.count)")
                
                completedTrackers = Set(try recordStore.fetchAllRecords())
                visibleCategories = categories
                collectionView.reloadData()
            } catch {
                print("❌ Ошибка: \(error)")
            }
        
        setupStores()
        setupNavigationBar()
        loadInitialData()
        updatePlaceholderVisibility()
        
        setupSearchService()
        setupCollectionView()
        setupUI()
        
    }
    
    private func setupDelegates() {
            trackerStore.delegate = self
            categoryStore.delegate = self
            recordStore.delegate = self
            searchService.delegate = self
        }
    
    private func setupStores() {
        do {
            try trackerStore.setupFetchedResultsController()
            try categoryStore.setupFetchedResultsController()
            try recordStore.setupFetchedResultsController()
            
            print("📊 После setupStores - sections: \(trackerStore.numberOfSections)")
            if trackerStore.numberOfSections > 0 {
                for section in 0..<trackerStore.numberOfSections {
                    print("📊 Section \(section) items: \(trackerStore.numberOfItemsInSection(section))")
                }
            }
            
        } catch {
            print("Ошибка настройки FRC: \(error)")
        }
    }
    
    private func loadInitialData() {
        do {
            categories = try categoryStore.fetchAllCategories()
            
            completedTrackers = Set(try recordStore.fetchAllRecords())
            
            visibleCategories = categories
            try trackerStore.fetchedResultsController.performFetch()
            print("📊 FRC sections: \(trackerStore.numberOfSections)")
            for section in 0..<trackerStore.numberOfSections {
                print("📊 FRC section \(section) items: \(trackerStore.numberOfItemsInSection(section))")
            }
            
            collectionView.reloadData()
            updatePlaceholderVisibility()
        } catch {
            print("Ошибка загрузки данных: \(error)")
        }
    }
    
    private func setupSearchService() {
            searchService.updateCategories(categories)
        }
    
    private func setupCollectionView() {
            collectionView.register(TrackerCategoryHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrackerCategoryHeader.reuseIdentifier)
            collectionView.dataSource = self
            collectionView.delegate = self
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
            TrackerCategory(header: "Важное", trackers: []),
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

        currentDate = Calendar.current.startOfDay(for: sender.date)

        collectionView.reloadData()
        updatePlaceholderVisibility()
    
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        print("Выбрана дата: \(formatter.string(from: currentDate))")
    }
    
    @objc private func addButtonTapped() {
        
        let newHabitVC = NewHabitViewController()
        newHabitVC.onSave = { [weak self] tracker, category in
            self?.addTracker(tracker, toCategoryAtIndex: category)
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
          
        print("🔥 Начинаем сохранение трекера: \(newTracker.name)")
            
        do {

            let categoryEntity: TrackerCategoryCoreData

            if let existingCategory = try categoryStore.fetchCategoryCoreData(by: categoryTitle) {

                categoryEntity = existingCategory
                print("✅ Найдена существующая категория: \(categoryTitle)")
            } else {
                print("🆕 Создаем новую категорию: \(categoryTitle)")
                _ = try categoryStore.createCategory(title: categoryTitle)

                guard let newCategory = try categoryStore.fetchCategoryCoreData(by: categoryTitle) else {
                    throw StoreError.categoryNotFound
                }
                categoryEntity = newCategory
            }

            print("📝 Создаем трекер в категории: \(categoryEntity.title ?? "nil")")

            let trackerEntity = TrackerCoreData(context: trackerStore.context)
            trackerEntity.trackerId = newTracker.id
            trackerEntity.nameTracker = newTracker.name
            trackerEntity.colorTracker = newTracker.color
            trackerEntity.emoji = newTracker.emoji
            
            print("   Сохраняем расписание напрямую: \(newTracker.schedule)")
            trackerEntity.setValue(newTracker.schedule, forKey: "schedule")
            trackerEntity.category = categoryEntity
            try trackerStore.saveContext()
            print("✅ Трекер сохранен: \(newTracker.name)")
            loadInitialData()
                
            } catch {
                print("❌ Ошибка сохранения трекера: \(error)")
            }
        
    }
    private func findIndexPath(for tracker: Tracker) -> IndexPath? {
        let visibleCategories = getVisibleCategories()
        
        for (section, category) in visibleCategories.enumerated() {
            for (item, visibleTracker) in category.trackers.enumerated() {
                if visibleTracker.id == tracker.id {
                    return IndexPath(item: item, section: section)
                }
            }
        }
        return nil
    }
    
    private func getVisibleCategories() -> [TrackerCategory] {

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        
        print("📅 Фильтрация для дня недели: \(weekday)")
        
        return visibleCategories.compactMap { category in
            let trackersForToday = category.trackers.filter { tracker in
                let contains = tracker.schedule.contains { $0.calendarWeekDay == weekday }
                print("   Трекер '\(tracker.name)', расписание: \(tracker.schedule.map { $0.rawValue }), подходит: \(contains)")
                return contains
            }
            return trackersForToday.isEmpty ? nil : TrackerCategory(
                header: category.header,
                trackers: trackersForToday
            )
        }
    }
    private func getSectionHeaderTitle(for section: Int) -> String {
            return "Важное"
        }

}

extension TrackersViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Unexpected element kind: \(kind)")
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackerCategoryHeader.reuseIdentifier, for: indexPath)  as? TrackerCategoryHeader ?? TrackerCategoryHeader()

        let title = getSectionHeaderTitle(for: indexPath.section)
        header.configure(with: title)
        return header
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        let visibleCategories = getVisibleCategories()
            print("📊 numberOfSections: \(visibleCategories.count)")
            return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
 
        let visibleCategories = getVisibleCategories()
        guard section < visibleCategories.count else { return 0 }
        
        let count = visibleCategories[section].trackers.count
        print("📊 section \(section) numberOfItems: \(count)")
        return count
        
                                                    
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
    
    private func handleTrackerToggle(tracker: Tracker, isCompleted: Bool) {
        print("🟢🟢🟢 handleTrackerToggle НАЧАЛО 🟢🟢🟢")
            print("   tracker: \(tracker.name)")
            print("   isCompleted: \(isCompleted)")
            print("   currentDate: \(currentDate)")
            
        let today = Calendar.current.startOfDay(for: currentDate)
        
        do {
            if isCompleted {
                print("   ➕ Вызываем addRecord")
                try recordStore.addRecord(trackerId: tracker.id, date: today)
            } else {
                print("   ➖ Вызываем removeRecord")
                try recordStore.removeRecord(trackerId: tracker.id, date: today)
            }
            
            completedTrackers = Set(try recordStore.fetchAllRecords())
            print("📊 completedTrackers обновлен: \(completedTrackers.count) записей")
            
            collectionView.reloadData()
            
        } catch {
            print("Ошибка обновления записи: \(error)")
        }
    }
    
    private func updatePlaceholderVisibility() {
        let visibleCategories = getVisibleCategories()
        let hasAnyTrackers = visibleCategories.contains { !$0.trackers.isEmpty }
        placeholderView.isHidden = hasAnyTrackers
        print("📱 placeholder скрыт: \(hasAnyTrackers)")
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.reuseIdentifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let visibleCategories = getVisibleCategories()
        guard indexPath.section < visibleCategories.count,
              indexPath.item < visibleCategories[indexPath.section].trackers.count else {
            return cell
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        
        if let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell {
                let newCount = (try? self.recordStore.countRecords(for: tracker.id)) ?? 0
                cell.updateCounter(newCount)
            }
        
        let completionCount = (try? recordStore.countRecords(for: tracker.id)) ?? 0

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
                ) { [weak self] isCompletedInCell in
                    
                    guard let self = self else { return }
                    
                    print("🔘 Нажатие на трекер '\(tracker.name)' at indexPath: [\(indexPath.section), \(indexPath.item)]")
                    
                    let today  = Calendar.current.startOfDay(for: self.currentDate)
                
                    do {
                        if isCompletedInCell {
                            print("   ➕ Добавляем запись в Core Data")
                            try self.recordStore.addRecord(trackerId: tracker.id, date: today)
                        } else {
                            print("   ➖ Удаляем запись из Core Data")
                            try self.recordStore.removeRecord(trackerId: tracker.id, date: today)
                        }
                        
                        self.completedTrackers = Set(try self.recordStore.fetchAllRecords())
                        print("📊 completedTrackers после обновления: \(self.completedTrackers.count)")
                        
                        collectionView.reloadItems(at: [indexPath])

                    } catch {
                        print("❌ Ошибка: \(error)")
                    }
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

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchService.filterCategories(searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
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
