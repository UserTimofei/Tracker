import UIKit

// MARK: - TrackersViewController
final class TrackersViewController: UIViewController, UICollectionViewDelegate, UISearchResultsUpdating, SearchServiceDelegate {
    
    // MARK: - Properties
    private var pinnedTrackers: Set<UUID> = []
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    
    private var isSearchActive: Bool {
        return navigationItem.searchController?.isActive ?? false &&
        !(navigationItem.searchController?.searchBar.text?.isEmpty ?? true)
    }
    
    private let store: TrackerStoreProtocol
    private let recordStore: RecordStoreProtocol
   
    private var currentDate = Date()
    private var currentWeekday: Int {
        return Calendar.current.component(.weekday, from: currentDate)
    }
    
    private let searchService = SearchService()
    
    private var currentFilter: TrackerFilter = .all {
        didSet {
            saveFilterState()
            updateFilterButtonAppearance()
            applyFilter()
        }
    }
    
    // MARK: - Initialization
    init(store: TrackerStoreProtocol, recordStore: RecordStoreProtocol) {
        self.store = store
        self.recordStore = recordStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Elements
    private lazy var filterButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle(NSLocalizedString("trackers.filter.button", comment: "Filters button"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 16
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
            return button
        }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = TrackersViewController.createLayout()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        return collectionView
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .compact
        picker.datePickerMode = .date
        picker.locale = Locale.current
        picker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        picker.calendar.firstWeekday = 2
        picker.date = currentDate
        return picker
    }()
    
    private let emptyFilterPlaceholderView: UIView = {
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let starImage = UIImageView(image: .appErrorSearch)
        starImage.tintColor = .appGray
        starImage.contentMode = .scaleAspectFit
        starImage.widthAnchor.constraint(equalToConstant: 80).isActive = true
        starImage.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let labelTextError = UILabel()
        labelTextError.translatesAutoresizingMaskIntoConstraints = false
        labelTextError.text = NSLocalizedString("trackers.empty_filter.title", comment: "Empty filter state text")
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
        labelTextError.text = NSLocalizedString("trackers.placeholder.title", comment: "Placeholder text when no trackers")
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadFilterState()
        setupDelegates()
        
        setupNavigationBar()
        
        setupSearchService()
        setupCollectionView()
        setupUI()
        
        loadInitialData()
        
        AnalyticsService.report(
            event: "open",
            params: [
                "screen": "Main"
            ]
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
 
        AnalyticsService.report(
            event: "close",
            params: [
                "screen": "Main"
            ]
        )
    }
    
    // MARK: - Setup Methods
    private func setupDelegates() {
        searchService.delegate = self
    }
    
    private func setupSearchService() {
        searchService.updateCategories(categories)
    }
    
    private func setupCollectionView() {
        collectionView.register(TrackerCategoryHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrackerCategoryHeader.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .appWhite
        
        view.addSubview(collectionView)
        view.addSubview(placeholderView)
        view.addSubview(emptyFilterPlaceholderView)
        view.addSubview(filterButton)
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        NSLayoutConstraint.activate([
            
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyFilterPlaceholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyFilterPlaceholderView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.heightAnchor.constraint(equalToConstant: 50),
            filterButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 114),
        ])
        
        collectionView.verticalScrollIndicatorInsets.bottom = 60
        collectionView.contentInset.bottom = 80
        
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
        search.searchBar.placeholder = NSLocalizedString("trackers.search.placeholder", comment: "Search placeholder")
        
        let doneButton = UIBarButtonItem(
            title: NSLocalizedString("common.done", comment: "Done"),
            style: .done,
            target: self,
            action: #selector(dismissKeyboardFromSearch)
        )
        
        let toolbar = UIToolbar()
        toolbar.items = [doneButton]
        search.searchBar.inputAccessoryView = toolbar
        
        navigationItem.searchController = search
        definesPresentationContext = true
        search.searchBar.delegate = self
        
        navigationItem.title = NSLocalizedString("trackers.title", comment: "Title for trackers screen")
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .year, value: -10, to: currentDate)
        let maxDate = calendar.date(byAdding: .year, value: 10, to: currentDate)
        datePicker.minimumDate = minDate
        datePicker.maximumDate = maxDate
    }
    
    // MARK: - Layout
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
    
    // MARK: - Data Loading
    private func loadInitialData() {
        do {
            categories = try store.fetchAllCategories()
            completedTrackers = Set(try recordStore.fetchAllRecords())
            
            if let pinnedIds = try? store.fetchAllPinnedTrackerIds() {
                pinnedTrackers = Set(pinnedIds)
            }
            searchService.updateCategories(categories)

            if !isSearchActive {
                visibleCategories = getVisibleCategories()
            }
            
            collectionView.reloadData()
            updatePlaceholderVisibility()
            updateFilterButtonVisibility()
        } catch {
            print("Ошибка загрузки данных: \(error)")
        }
    }
    
    // MARK: - Filter Methods
    private func applyFilter() {
        print("🔄 Применение фильтра: \(currentFilter.title)")
        
        visibleCategories = getVisibleCategories()
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updatePlaceholderVisibility()
            self.updateFilterButtonVisibility()
        }
    }
    
    private func updateFilterButtonVisibility() {
        let hasAnyTrackersInDB = !categories.flatMap { $0.trackers }.isEmpty
        filterButton.isHidden = !hasAnyTrackersInDB
    }
    
    
    private func updateFilterButtonAppearance() {
        if currentFilter.isStrictFilter {
            filterButton.backgroundColor = .systemRed
        } else {
            filterButton.backgroundColor = .systemBlue
        }
    }
    
    private func saveFilterState() {
        UserDefaults.standard.set(currentFilter.rawValue, forKey: "SelectedTrackerFilter")
    }

    private func loadFilterState() {
        let rawValue = UserDefaults.standard.integer(forKey: "SelectedTrackerFilter")
        currentFilter = TrackerFilter(rawValue: rawValue) ?? .all
    }
    
    // MARK: - Visibility Helpers
    private func updatePlaceholderVisibility() {
        let hasAnyTrackersInDB = !categories.flatMap { $0.trackers }.isEmpty
        let weekday = Calendar.current.component(.weekday, from: currentDate)
        var trackersCountForDay = 0
        for category in categories {
            trackersCountForDay += category.trackers.filter {
                $0.schedule.contains { $0.calendarWeekDay == weekday }
            }.count
        }
        let hasTrackersForSelectedDay = trackersCountForDay > 0
        let totalVisibleTrackers = visibleCategories.reduce(0) { $0 + $1.trackers.count }
        let hasVisibleTrackers = totalVisibleTrackers > 0
        
        let shouldShowMainPlaceholder = !hasAnyTrackersInDB ||
        (!hasTrackersForSelectedDay) ||
        (!currentFilter.isStrictFilter && !hasVisibleTrackers)
        
        placeholderView.isHidden = !shouldShowMainPlaceholder
        
        let shouldShowFilterPlaceholder = hasTrackersForSelectedDay &&
        currentFilter.isStrictFilter &&
        !hasVisibleTrackers
        
        emptyFilterPlaceholderView.isHidden = !shouldShowFilterPlaceholder
        filterButton.isHidden = !hasTrackersForSelectedDay
    }
    
    // MARK: - Data Helpers
    private func isCompleted(trackerId: UUID, on date: Date) -> Bool {
        let targetDay = Calendar.current.startOfDay(for: date)
        return completedTrackers.contains { record in
            record.trackerId == trackerId &&
            Calendar.current.isDate(record.date, inSameDayAs: targetDay)
        }
    }
    
    private func isFutureDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let selectedDateStart = calendar.startOfDay(for: date)
        return selectedDateStart > todayStart
    }
    
    private func getVisibleCategories() -> [TrackerCategory] {
        let weekday = Calendar.current.component(.weekday, from: currentDate)

        var trackersForSelectedDay: [Tracker] = []
        
        for category in categories {
            let trackers = category.trackers.filter { tracker in
                tracker.schedule.contains { $0.calendarWeekDay == weekday }
            }
            trackersForSelectedDay.append(contentsOf: trackers)
        }
        
        var filteredTrackers: [Tracker] = []
        
        switch currentFilter {
        case .all, .today:
            filteredTrackers = trackersForSelectedDay
        case .completed:
            filteredTrackers = trackersForSelectedDay.filter { tracker in
                isCompleted(trackerId: tracker.id, on: currentDate)
            }
            
        case .uncompleted:
            filteredTrackers = trackersForSelectedDay.filter { tracker in
                !isCompleted(trackerId: tracker.id, on: currentDate)
            }
        }
        return groupTrackersByCategory(trackers: filteredTrackers)
    }
    
    private func groupTrackersByCategory(trackers: [Tracker]) -> [TrackerCategory] {
        let pinned = trackers.filter { pinnedTrackers.contains($0.id) }
        let regular = trackers.filter { !pinnedTrackers.contains($0.id) }
        
        var regularCategories: [TrackerCategory] = []
        for category in categories {
            let trackersInCategory = regular.filter { tracker in
                category.trackers.contains { $0.id == tracker.id }
            }
            if !trackersInCategory.isEmpty {
                regularCategories.append(TrackerCategory(header: category.header, trackers: trackersInCategory))
            }
        }
        
        var result: [TrackerCategory] = []
        if !pinned.isEmpty {
            result.append(TrackerCategory(header: NSLocalizedString("pinned.section", comment: ""), trackers: pinned))
        }
        result.append(contentsOf: regularCategories)
        return result
    }
    
    private func getSectionHeaderTitle(for section: Int) -> String {
        guard section < visibleCategories.count else { return "" }
        return visibleCategories[section].header
    }
    
    // MARK: - Tracker Actions
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
    
    // MARK: - Actions
    
    @objc private func filterButtonTapped() {
        AnalyticsService.report(
            event: "click",
            params: [
                "screen": "Main",
                "item": "filter"
            ]
        )
        
        let filterVC = FilterViewController(currentFilter: currentFilter)
        filterVC.delegate = self
        
        let navController = UINavigationController(rootViewController: filterVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        currentDate = Calendar.current.startOfDay(for: sender.date)

        if !isSearchActive {
            visibleCategories = getVisibleCategories()
            collectionView.reloadData()
            updatePlaceholderVisibility()
        } else {

            collectionView.reloadData()
        }
        
        updatePlaceholderVisibility()
    }
    
    @objc private func addButtonTapped() {
        
        AnalyticsService.report(
            event: "click",
            params: [
                "screen": "Main",
                "item": "add_track"
            ]
        )
        
        let newHabitVC = NewHabitViewController()
        newHabitVC.onSave = { [weak self] tracker, category in
            self?.addTracker(tracker, toCategoryAtIndex: category)
        }
        let navController = UINavigationController(rootViewController: newHabitVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    @objc private func dismissKeyboardFromSearch() {
        if let searchController = navigationItem.searchController {
            searchController.isActive = false
            searchController.searchBar.resignFirstResponder()
        }
    }
    
    // MARK: - Search
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
        print("🔍 ПОИСК: Введен текст '\(searchText)'")
        
        if searchText.isEmpty {
            print("🔍 ПОИСК: Текст пуст, сброс")

            visibleCategories = categories
            collectionView.reloadData()
        } else {
            print("🔍 ПОИСК: Запуск фильтрации")

            searchService.filterCategories(searchText: searchText)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension TrackersViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Unexpected element kind: \(kind)")
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackerCategoryHeader.reuseIdentifier, for: indexPath)  as? TrackerCategoryHeader ?? TrackerCategoryHeader()
        header.configure(with: visibleCategories[indexPath.section].header)
        return header
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.reuseIdentifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        guard indexPath.section < visibleCategories.count,
              indexPath.item < visibleCategories[indexPath.section].trackers.count else {
            return cell
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        
        let isPinned = pinnedTrackers.contains(tracker.id)
        print("📍 Трекер '\(tracker.name)', isPinned: \(isPinned)")
        
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
            
            AnalyticsService.report(
                event: "click",
                params: [
                    "screen": "Main",
                    "item": "track"
                ]
            )
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
                if self.currentFilter.isStrictFilter {
                    self.applyFilter()
                } else {
                    collectionView.reloadItems(at: [indexPath])
                }
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
            let pinTitle = isPinned
            ? NSLocalizedString("tracker.unpin", comment: "Unpin tracker")
            : NSLocalizedString("tracker.pin", comment: "Pin tracker")
            let pinImage = isPinned ? "pin.slash" : "pin"
            
            let pinAction = UIAction(
                title: pinTitle,
                image: UIImage(systemName: pinImage)
            ) { [weak self] _ in
                self?.togglePin(for: tracker)
            }
            let editAction = UIAction(
                title: NSLocalizedString("common.edit", comment: "Edit"),
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                
                AnalyticsService.report(
                    event: "click",
                    params: [
                        "screen": "Main",
                        "item": "edit"
                    ]
                )
                
                self?.editTracker(tracker)
            }

            let deleteAction = UIAction(
                title: NSLocalizedString("common.delete", comment: "Delete"),
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                
                AnalyticsService.report(
                    event: "click",
                    params: [
                        "screen": "Main",
                        "item": "delete"
                    ]
                )
                
                self?.showDeleteConfirmation(for: tracker)
            }
            
            return UIMenu(children: [pinAction, editAction, deleteAction])
        })
    }
}

// MARK: - UISearchBarDelegate
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

// MARK: - Actions with Trackers
extension TrackersViewController {
    
    private func togglePin(for tracker: Tracker) {
        do {
            try store.togglePin(for: tracker.id)

            if pinnedTrackers.contains(tracker.id) {
                pinnedTrackers.remove(tracker.id)
            } else {
                pinnedTrackers.insert(tracker.id)
            }

            loadInitialData()
            
        } catch {
            print("❌ Ошибка при закреплении: \(error)")
            showErrorAlert(NSLocalizedString("error.pin", comment: "Pin error message"))
        }
    }
    
    private func editTracker(_ tracker: Tracker) {
        print("✏️ Редактирование трекера: \(tracker.name)")
        print("📅 Расписание трекера: \(tracker.schedule.map { $0.rawValue })") //
 
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
            showErrorAlert(NSLocalizedString("error.update", comment: "Update error message"))
        }
    }
    
    private func showDeleteConfirmation(for tracker: Tracker) {
        let alert = UIAlertController(
            title: NSLocalizedString("delete.title", comment: "Delete confirmation title"),
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(
            title: NSLocalizedString("common.delete", comment: "Delete"),
            style: .destructive
        ) { [weak self] _ in
            self?.deleteTracker(tracker)
        }
        
        let cancelAction = UIAlertAction(
            title:  NSLocalizedString("common.cancel", comment: "Cancel"),
            style: .cancel
        )
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func deleteTracker(_ tracker: Tracker) {
        do {
            let records = try recordStore.fetchAllRecords()
            for record in records {
                if record.trackerId == tracker.id {
                    try recordStore.removeRecord(trackerId: tracker.id, date: record.date)
                }
            }
            
            try store.deleteTracker(id: tracker.id)
            NotificationCenter.default.post(name: .trackerRecordsDidUpdate, object: nil)
            loadInitialData()
        } catch {
            print("❌ Ошибка при удалении: \(error)")
            showErrorAlert(NSLocalizedString("error.delete", comment: "Delete error message"))
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("error.title", comment: "Error alert title"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.ok", comment: "OK"),
            style: .default
        ))
        present(alert, animated: true)
    }
}
// MARK: - FilterViewControllerDelegate
extension TrackersViewController: FilterViewControllerDelegate {
    func didSelectFilter(_ filter: TrackerFilter) {
        
        print("🎛 Выбран фильтр: \(filter.title)")
        
        if filter == .today {
            currentDate = Date()
            datePicker.date = Date()
        }
        currentFilter = filter
    }
    
}

// MARK: - Testing
extension TrackersViewController {
    func setTestDate(_ date: Date) {
        currentDate = date
        if let datePicker = navigationItem.rightBarButtonItem?.customView as? UIDatePicker {
            datePicker.date = date
        }
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }
}
