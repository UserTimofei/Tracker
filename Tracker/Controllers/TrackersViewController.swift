import UIKit

class TrackersViewController: UIViewController, UICollectionViewDelegate, UISearchResultsUpdating, SearchServiceDelegate {
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
    private var pinnedTrackers: Set<UUID> = []
    
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    
    private let store: TrackerStoreProtocol
    private let recordStore: RecordStoreProtocol
    
    init(store: TrackerStoreProtocol, recordStore: RecordStoreProtocol) {
        self.store = store
        self.recordStore = recordStore
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var currentDate = Date()
    private var currentWeekday: Int {
        return Calendar.current.component(.weekday, from: currentDate)
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
        
        setupNavigationBar()
        loadInitialData()
        setupSearchService()
        setupCollectionView()
        setupUI()
        
    }
    
    private func setupDelegates() {
        searchService.delegate = self
    }
    
    private func loadInitialData() {
        do {
            categories = try store.fetchAllCategories()
            completedTrackers = Set(try recordStore.fetchAllRecords())
            
            if let pinnedIds = try? store.fetchAllPinnedTrackerIds() {
                pinnedTrackers = Set(pinnedIds)
            }
            
            visibleCategories = categories
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
            try store.addTracker(newTracker, toCategory: categoryTitle)
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
        
        //        return categories.compactMap { category in
        //            let trackersForToday = category.trackers.filter { tracker in
        //                let contains = tracker.schedule.contains { $0.calendarWeekDay == weekday }
        //                print("   Трекер '\(tracker.name)', расписание: \(tracker.schedule.map { $0.rawValue }), подходит: \(contains)")
        //                return contains
        //            }
        //            return trackersForToday.isEmpty ? nil : TrackerCategory(
        //                header: category.header,
        //                trackers: trackersForToday
        //            )
        //        }
        
        // Сначала собираем все трекеры на сегодня
        var allTodayTrackers: [Tracker] = []
        for category in categories {
            let trackersForToday = category.trackers.filter { tracker in
                tracker.schedule.contains { $0.calendarWeekDay == weekday }
            }
            allTodayTrackers.append(contentsOf: trackersForToday)
        }
        
        // Разделяем на закрепленные и обычные
        let pinned = allTodayTrackers.filter { pinnedTrackers.contains($0.id) }
        let regular = allTodayTrackers.filter { !pinnedTrackers.contains($0.id) }
        
        // Группируем обычные по категориям
        var regularCategories: [TrackerCategory] = []
        for category in categories {
            let trackersInCategory = regular.filter { tracker in
                // Находим оригинальную категорию трекера
                category.trackers.contains { $0.id == tracker.id }
            }
            if !trackersInCategory.isEmpty {
                regularCategories.append(TrackerCategory(
                    header: category.header,
                    trackers: trackersInCategory
                ))
            }
        }
        
        // Формируем результат: сначала закрепленные, потом остальные категории
        var result: [TrackerCategory] = []
        if !pinned.isEmpty {
            result.append(TrackerCategory(header: "Закрепленные", trackers: pinned))
        }
        result.append(contentsOf: regularCategories)
        
        return result
        
    }
    
    private func getSectionHeaderTitle(for section: Int) -> String {
        let visibleCategories = getVisibleCategories()
        guard section < visibleCategories.count else { return "" }
        return visibleCategories[section].header
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
        
        let isPinned = pinnedTrackers.contains(tracker.id)
        print("📍 Трекер '\(tracker.name)', isPinned: \(isPinned)")
        
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
            isPinned: isPinned,
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

// MARK: - UICollectionViewDelegate
extension TrackersViewController {
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let indexPath = indexPaths.first else { return nil }
        
        let visibleCategories = getVisibleCategories()
        guard indexPath.section < visibleCategories.count,
              indexPath.item < visibleCategories[indexPath.section].trackers.count else {
            return nil
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let isPinned = pinnedTrackers.contains(tracker.id)
        
        return UIContextMenuConfiguration(actionProvider: { _ in
            
            // 👇 Пункт "Закрепить/Открепить"
            let pinTitle = isPinned ? "Открепить" : "Закрепить"
            let pinImage = isPinned ? "pin.slash" : "pin"
            
            let pinAction = UIAction(
                title: pinTitle,
                image: UIImage(systemName: pinImage)
            ) { [weak self] _ in
                self?.togglePin(for: tracker)
            }
            
            // 👇 Пункт "Редактировать"
            let editAction = UIAction(
                title: "Редактировать",
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                self?.editTracker(tracker)
            }
            
            // 👇 Пункт "Удалить"
            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.showDeleteConfirmation(for: tracker)
            }
            
            return UIMenu(children: [pinAction, editAction, deleteAction])
        })
    }
}

// MARK: - Actions with Trackers
extension TrackersViewController {
    
    private func togglePin(for tracker: Tracker) {
        do {
            try store.togglePin(for: tracker.id)
            
            // Обновляем локальный кэш
            if pinnedTrackers.contains(tracker.id) {
                pinnedTrackers.remove(tracker.id)
            } else {
                pinnedTrackers.insert(tracker.id)
            }
            
            // Перезагружаем данные для отображения в правильном порядке
            loadInitialData()
            
        } catch {
            print("❌ Ошибка при закреплении: \(error)")
            showErrorAlert("Не удалось изменить статус закрепления")
        }
    }
    
    private func editTracker(_ tracker: Tracker) {
        print("✏️ Редактирование трекера: \(tracker.name)")
        print("📅 Расписание трекера: \(tracker.schedule.map { $0.rawValue })") // 👈 Отладка
 
        let completedDaysCount = (try? recordStore.countRecords(for: tracker.id)) ?? 0
        print("📊 Количество выполненных дней: \(completedDaysCount)")
        
        guard let categoryTitle = try? store.fetchCategoryForTracker(trackerId: tracker.id) else {
            print("❌ Не удалось получить категорию трекера")
            return
        }
        
        let editVC = NewHabitViewController(
            mode: .edit(tracker),
            store: store,
            completedDaysCount: completedDaysCount
        )
        editVC.onSave = { [weak self] updatedTracker, category in
            self?.updateTracker(updatedTracker, category: category)
        }
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    private func updateTracker(_ tracker: Tracker, category: String) {
        do {
            try store.updateTracker(newTracker: tracker, categoryTitle: category)
            loadInitialData()
        } catch {
            print("❌ Ошибка при обновлении: \(error)")
            showErrorAlert("Не удалось обновить трекер")
        }
    }
    
    private func showDeleteConfirmation(for tracker: Tracker) {
        let alert = UIAlertController(
            title: "Удалить трекер?",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.deleteTracker(tracker)
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func deleteTracker(_ tracker: Tracker) {
        do {
            // Нужно добавить метод deleteTracker в протокол
            try store.deleteTracker(id: tracker.id)
            loadInitialData()
        } catch {
            print("❌ Ошибка при удалении: \(error)")
            showErrorAlert("Не удалось удалить трекер")
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
