import UIKit

enum Section: Int, CaseIterable {
    case emoji
    case color
    
    var title: String {
        switch self {
        case .emoji: return "Emoji"
        case .color: return "Цвет"
        }
    }
}

enum HabitMode {
    case create
    case edit(Tracker)
    
    static func == (lhs: HabitMode, rhs: HabitMode) -> Bool {
        switch (lhs, rhs) {
        case (.create, .create):
            return true
        case (.edit(let lhsTracker), .edit(let rhsTracker)):
            return lhsTracker.id == rhsTracker.id
        default:
            return false
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .create:
            return "Создать"
        case .edit:
            return "Сохранить"
        }
    }
    
    var navigationTitle: String {
        switch self {
        case .create:
            return "Новая привычка"
        case .edit:
            return "Редактирование привычки"
        }
    }
}

class NewHabitViewController: UIViewController, UITextFieldDelegate {
    
    var onSave: ((Tracker, String) -> Void)?
    private var mode: HabitMode
    private var selectedSchedule: Set<WeekDay> = []
    private var categoryTitleLabel: UILabel?
    private var editingTracker: Tracker?
    private var completedDaysCount: Int = 0
   
    private var categoryScheduleBlockTopWhenErrorHidden: NSLayoutConstraint!
    private var categoryScheduleBlockTopWhenErrorVisible: NSLayoutConstraint!
    private var scheduleDisplayText: String {
        if selectedSchedule.count == WeekDay.allCases.count {
            return "Каждый день"
        } else {
            let sortedDays = selectedSchedule.sorted { $0.calendarWeekDay < $1.calendarWeekDay }
            let shortTitles = sortedDays.map { $0.shortTitle }
            print("📅 Дни для отображения: \(shortTitles)")
            return shortTitles.joined(separator: ", ")
        }
    }
    
    private var selectedCategoryTitle: String = "Важное" {
        didSet {
            DispatchQueue.main.async {
                self.updateCategoryButtonTitle()
                print("🔄 Обновляем заголовок категории на: \(self.selectedCategoryTitle)")
            }
        }
    }

    private let emojis: [String] = ["🙂", "😊", "😎", "😴", "😭", "😡", "🥶", "🤔", "🐶", "🐱", "🍕", "🏀", "✈️", "💻", "🎸", "⚽️"]
    private let colors: [UIColor] = [.appColorSelection1, .appColorSelection2, .appColorSelection3, .appColorSelection4, .appColorSelection5, .appColorSelection6, .appColorSelection7, .appColorSelection8, .appColorSelection9, .appColorSelection10, .appColorSelection11, .appColorSelection12, .appColorSelection13, .appColorSelection14, .appColorSelection15, .appColorSelection16, .appColorSelection17, .appColorSelection18]
    
    init(mode: HabitMode = .create, store: TrackerStoreProtocol? = nil, completedDaysCount: Int = 0) {
        self.mode = mode
        self.completedDaysCount = completedDaysCount
        super.init(nibName: nil, bundle: nil)
        
        if case .edit(let tracker) = mode, let store = store {
            self.editingTracker = tracker
            self.selectedSchedule = tracker.schedule
            print("📅 Инициализация с расписанием: \(tracker.schedule.map { $0.rawValue })")
            print("📊 Передано дней для отображения: \(completedDaysCount)")
            
            if let categoryTitle = try? store.fetchCategoryForTracker(trackerId: tracker.id) {
                self.selectedCategoryTitle = categoryTitle
                print("📁 Категория трекера: \(categoryTitle)")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var completedDaysLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .appBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private lazy var emojiCollectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.allowsSelection = true
        collection.isScrollEnabled = false
        
        collection.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseIdentifier)
        collection.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseIdentifier)
        collection.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderView.reuseIdentifier)
        
        return collection
    }()
    
    private var selectedEmojiIndex: Int? = nil
    private var selectedColorIndex: Int? = nil
    
    private lazy var textField: UITextField = {
        let text = UITextField()
        text.placeholder = "Введите название трекера"
        text.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        text.borderStyle = .none
        text.layer.cornerRadius = 16
        text.clipsToBounds = true
        text.backgroundColor = .appBackground
        text.delegate = self
        text.translatesAutoresizingMaskIntoConstraints = false
        
        text.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        return text
    }()
    
    private lazy var keyboardToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        let cancel = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(dismissKeyboard)
        )
        
        toolbar.items = [flexibleSpace, cancel]
        return toolbar
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .appRed
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var categoryScheduleBlock: UIView = {
        let view = UIView()
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitle("Категория", for: .normal)
        button.setTitleColor(.appBlack, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 32)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addTapCategory), for: .touchUpInside)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .appGray
        chevron.contentMode = .center
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -24),
            chevron.centerYAnchor.constraint(equalTo: button.titleLabel!.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 7),
            chevron.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        button.layer.maskedCorners = [ .layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        return button
    }()
    
    private lazy var scheduleButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitle("Расписание", for: .normal)
        button.setTitleColor(.appBlack, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.contentVerticalAlignment = .center
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 32)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addTapSchedule), for: .touchUpInside)
    
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .appGray
        chevron.contentMode = .center
        chevron.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -24),
            chevron.centerYAnchor.constraint(equalTo: button.titleLabel!.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 7),
            chevron.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        button.layer.maskedCorners = [ .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        return button
    }()

    private let dividerView: UIView = {
            let view = UIView()
            view.backgroundColor = .appGray
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .appGray
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        switch mode {
           case .create:
               button.setTitle("Создать", for: .normal)
           case .edit:
               button.setTitle("Сохранить", for: .normal)
           }
        button.setTitleColor(.appWhite, for: .normal)
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .appWhite
        button.layer.cornerRadius = 16
        button.layer.borderColor = UIColor.appRed.cgColor
        button.layer.borderWidth = 1.0
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.appRed, for: .normal)
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelTapButton), for: .touchUpInside)
        return button
    }()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        switch mode {
        case .create:
            navigationItem.title = "Новая привычка"
        case .edit:
            navigationItem.title = "Редактирование привычки"
        }
        view.backgroundColor = .appWhite
        emojiCollectionView.dataSource = self
        emojiCollectionView.delegate = self
        setupUI()
        
        if case .edit(let tracker) = mode {
            fillData(with: tracker)
        }
        
        conditionCreateButton()
        updateCategoryButtonTitle()
        
    }
    
    private func fillData(with tracker: Tracker) {
        textField.text = tracker.name
        
        if completedDaysCount > 0 {
            let word = TrackerCell.declinationOfDays(completedDaysCount)
            completedDaysLabel.text = "\(completedDaysCount) \(word)"
            print("✅ Отображаем дни: \(completedDaysCount) \(word)")
        } else {
            print("⚠️ completedDaysCount = 0, ничего не отображаем")
        }
        
        selectedSchedule = tracker.schedule
        print("📅 fillData: selectedSchedule = \(selectedSchedule.map { $0.rawValue })")

        if let emojiIndex = emojis.firstIndex(of: tracker.emoji) {
            selectedEmojiIndex = emojiIndex
        }
        
        if let colorIndex = colors.firstIndex(where: { $0 == tracker.color }) {
            selectedColorIndex = colorIndex
        }
 
        updateCategoryButtonTitle()
        updateScheduleButtonTitle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("=== ПОДРОБНАЯ ОТЛАДКА ===")
        print("scrollView frame: \(scrollView.frame)")
        print("scrollView contentSize: \(scrollView.contentSize)")
        print("contentView frame: \(contentView.frame)")
        print("textField frame: \(textField.frame)")
        print("categoryScheduleBlock frame: \(categoryScheduleBlock.frame)")
        print("emojiCollectionView frame: \(emojiCollectionView.frame)")
        
        let totalContentHeight = textField.frame.height + 24 +
                                categoryScheduleBlock.frame.height + 32 +
                                emojiCollectionView.frame.height + 32
        print("Расчетная высота контента: \(totalContentHeight)")
        print("scrollView bounds height: \(scrollView.bounds.height)")
        print("Нужен скролл: \(totalContentHeight > scrollView.bounds.height)")

        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
    }
    
    private func setupUI() {
        let stackBottomButton = UIStackView()
        stackBottomButton.axis = .horizontal
        stackBottomButton.spacing = 8
        stackBottomButton.distribution = .fillEqually
        stackBottomButton.translatesAutoresizingMaskIntoConstraints = false
        
        stackBottomButton.addArrangedSubview(cancelButton)
        stackBottomButton.addArrangedSubview(createButton)
        view.addSubview(stackBottomButton)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
 
        contentView.addSubview(textField)
        contentView.addSubview(errorLabel)
        
        if case .edit = mode {
            contentView.addSubview(completedDaysLabel)
            print("✅ Добавлен completedDaysLabel для режима редактирования")
        }
        
        categoryScheduleBlock.backgroundColor = .appBackground
        contentView.addSubview(categoryScheduleBlock)
        
        contentView.addSubview(emojiCollectionView)
        
        categoryScheduleBlock.addSubview(categoryButton)
        categoryScheduleBlock.addSubview(scheduleButton)
        categoryScheduleBlock.addSubview(dividerView)
        
        textField.inputAccessoryView = keyboardToolbar
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always

        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.rightView = rightPaddingView
        textField.rightViewMode = .always
        
        NSLayoutConstraint.activate([
               errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
               errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               errorLabel.heightAnchor.constraint(equalToConstant: 20),
           ])
        
        if case .edit = mode {
            print("📌 Активируем констрейнты для режима редактирования")
            NSLayoutConstraint.activate([
                completedDaysLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
                completedDaysLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                
                textField.topAnchor.constraint(equalTo: completedDaysLabel.bottomAnchor, constant: 40),
                textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                textField.heightAnchor.constraint(equalToConstant: 75),
                
                categoryScheduleBlock.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24),
                categoryScheduleBlock.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                categoryScheduleBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                categoryScheduleBlock.heightAnchor.constraint(equalToConstant: 150.5),
            ])
        } else {
            print("📌 Активируем констрейнты для режима создания")
            NSLayoutConstraint.activate([
                textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
                textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                textField.heightAnchor.constraint(equalToConstant: 75),
                
                categoryScheduleBlock.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24),
                categoryScheduleBlock.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                categoryScheduleBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                categoryScheduleBlock.heightAnchor.constraint(equalToConstant: 150.5),
            ])
        }
        
        NSLayoutConstraint.activate([
            categoryButton.topAnchor.constraint(equalTo: categoryScheduleBlock.topAnchor),
            categoryButton.heightAnchor.constraint(equalToConstant: 75),
            categoryButton.leadingAnchor.constraint(equalTo: categoryScheduleBlock.leadingAnchor),
            categoryButton.trailingAnchor.constraint(equalTo: categoryScheduleBlock.trailingAnchor),
            
            dividerView.topAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            dividerView.leadingAnchor.constraint(equalTo: categoryButton.leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: categoryButton.trailingAnchor, constant: -16),
            dividerView.heightAnchor.constraint(equalToConstant: 0.5),
        
            scheduleButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor),
            scheduleButton.leadingAnchor.constraint(equalTo: categoryScheduleBlock.leadingAnchor),
            scheduleButton.trailingAnchor.constraint(equalTo: categoryScheduleBlock.trailingAnchor),
            scheduleButton.heightAnchor.constraint(equalToConstant: 75),
            scheduleButton.bottomAnchor.constraint(equalTo: categoryScheduleBlock.bottomAnchor),
            
            emojiCollectionView.topAnchor.constraint(equalTo: categoryScheduleBlock.bottomAnchor, constant: 32),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: 550),
            emojiCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            
        ])
        
        NSLayoutConstraint.activate([
            stackBottomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackBottomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackBottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackBottomButton.heightAnchor.constraint(equalToConstant: 60),
            
            
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: stackBottomButton.topAnchor, constant: -8),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo:  scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            
        ])
        
        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
        
        categoryScheduleBlockTopWhenErrorHidden = categoryScheduleBlock.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24)
        categoryScheduleBlockTopWhenErrorVisible = categoryScheduleBlock.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 32)
        
        if case .edit = mode {
            categoryScheduleBlockTopWhenErrorHidden.isActive = false
            categoryScheduleBlockTopWhenErrorVisible.isActive = false
            print("🔽 Старые констрейнты деактивированы для режима редактирования")
        } else {
            categoryScheduleBlockTopWhenErrorHidden.isActive = true
            print("🔽 Стандартный констрейнт активирован для режима создания")
        }
    }
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            guard let section = Section(rawValue: sectionIndex) else {
                return nil
            }
            
            switch section {
            case .emoji:
                return self.createEmojiSection()
            case .color:
                return self.createColorSection()
            }
        }
        return layout
    }
    
    private func createEmojiSection() -> NSCollectionLayoutSection {
        createGridSection(
            numberOfItemsPerRow: 6,
            interItemSpacing: 5,
            sectionInsets: NSDirectionalEdgeInsets(top: 24, leading: 18, bottom: 24, trailing: 18)
        )
    }
    private func createColorSection() -> NSCollectionLayoutSection {
        createGridSection(
            numberOfItemsPerRow: 6,
            interItemSpacing: 5,
            sectionInsets: NSDirectionalEdgeInsets(top: 24, leading: 18, bottom: 24, trailing: 18)
        )
    }
    
    private func createGridSection(
        numberOfItemsPerRow: Int,
        interItemSpacing: CGFloat,
        sectionInsets: NSDirectionalEdgeInsets
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(numberOfItemsPerRow)),
            heightDimension: .fractionalWidth(1.0 / CGFloat(numberOfItemsPerRow))
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: interItemSpacing / 2,
            bottom: 0,
            trailing: interItemSpacing / 2
        )
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: itemSize.heightDimension
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: numberOfItemsPerRow
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = sectionInsets
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(40)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    
    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }
    
    @objc private func addTapCategory() {
        
        let categoryVC = CategoryViewController(selectedCategory: selectedCategoryTitle)
        categoryVC.onCategorySelected = { [weak self] categoryTitle in
            self?.selectedCategoryTitle = categoryTitle
            print("✅ Выбрана категория: \(categoryTitle)")
        }
        
        navigationController?.pushViewController(categoryVC, animated: true)
    }
    
    
    @objc private func createButtonTapped() {
        guard let name = textField.text,
              !name.isEmpty,
              let emojiIndex = selectedEmojiIndex,
              let colorIndex = selectedColorIndex else { return }
        
        print("📦 NewHabitVC: создаем трекер с расписанием: \(selectedSchedule.map { $0.rawValue })")
        
        let trackerId: UUID
        switch mode {
        case .create:
            trackerId = UUID()
        case .edit(let tracker):
            trackerId = tracker.id
        }
        
        let newTracker = Tracker(
            id: mode == .create ? UUID() : (editingTracker?.id ?? UUID()),
            name: name,
            color: colors[colorIndex],
            emoji: emojis[emojiIndex],
            schedule: selectedSchedule)
        
        print("🚀 NewHabitVC: отправляем трекер в TrackersViewController с категорией: \(selectedCategoryTitle)")
        
        onSave?(newTracker, selectedCategoryTitle)
        
        dismiss(animated: true)
    }
    
    @objc private func addTapSchedule() {
        print("📥 NewHabitVC: открываем ScheduleVC с текущими днями: \(selectedSchedule.map { $0.rawValue })")
        let newScheduleVC = ScheduleVC()
        
        newScheduleVC.selectedDays = selectedSchedule
        newScheduleVC.onSave = { [weak self] days in
            print("📥 NewHabitVC: получили дни обратно: \(days.map { $0.rawValue })")
            guard let self = self else { return }
            self.selectedSchedule = Set(days)
            updateScheduleButtonTitle()
            conditionCreateButton()
        }
        navigationController?.pushViewController(newScheduleVC, animated: true)
    }
    
    private func updateScheduleButtonTitle() {
        let displayText = scheduleDisplayText
        print("📝 Обновление расписания: displayText = \(displayText)")
        
        let fullText = "Расписание\n\(displayText)"
        
        let attributed = NSMutableAttributedString(string: fullText)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            .foregroundColor: UIColor.appBlack
        ]
        
        let daysAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            .foregroundColor: UIColor.appGray
        ]

        let titleWithNewline = "Расписание\n"
        let titleRange = NSRange(location: 0, length: titleWithNewline.utf16.count)
        let daysRange = NSRange(location: titleRange.length, length: displayText.utf16.count)
        
        attributed.setAttributes(titleAttributes, range: titleRange)
        attributed.setAttributes(daysAttributes, range: daysRange)
        
        DispatchQueue.main.async {
            self.scheduleButton.titleLabel?.numberOfLines = 0
            self.scheduleButton.titleLabel?.lineBreakMode = .byWordWrapping
            self.scheduleButton.setAttributedTitle(attributed, for: .normal)
            print("✅ Кнопка расписания обновлена: \(fullText)")
        }
    }
    
    private func updateCategoryButtonTitle() {
        
        let titleText = selectedCategoryTitle
        print("📝 updateCategoryButtonTitle вызван с titleText: \(titleText)")
        
        let fullText = "Категория\n\(titleText)"
        
        let attributed = NSMutableAttributedString(string: fullText)
        
        let mainTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            .foregroundColor: UIColor.appBlack
        ]
        
        let categoryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            .foregroundColor: UIColor.appGray
        ]

        let titleWithNewline = "Категория\n"
        let mainTitleRange = NSRange(location: 0, length: titleWithNewline.utf16.count)
        
        let categoryRange = NSRange(location: mainTitleRange.length, length: titleText.utf16.count)
        
        attributed.setAttributes(mainTitleAttributes, range: mainTitleRange)
        attributed.setAttributes(categoryAttributes, range: categoryRange)
        
        
        DispatchQueue.main.async {
                self.categoryButton.titleLabel?.numberOfLines = 0
                self.categoryButton.titleLabel?.lineBreakMode = .byWordWrapping
                self.categoryButton.setAttributedTitle(attributed, for: .normal)
            }
        
    }
    
    private func conditionCreateButton() {
        let hasName = !(textField.text?.isEmpty ?? true)
        let hasSchedule = !selectedSchedule.isEmpty
        
        let hasEmoji = selectedEmojiIndex != nil
        let hasColor = selectedColorIndex != nil
        

        let isValid = hasName && hasSchedule && hasEmoji && hasColor
        
        createButton.isEnabled = isValid
        createButton.backgroundColor = isValid ? .appBlack : .appGray
    }
    
    @objc private func cancelTapButton() {
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange() {
        guard let text = textField.text else { return }
        
        let isOverLimit = text.count >= 38
        
        errorLabel.isHidden = !isOverLimit
        
        categoryScheduleBlockTopWhenErrorHidden.isActive = !isOverLimit
        categoryScheduleBlockTopWhenErrorVisible.isActive = isOverLimit
        conditionCreateButton()
    }
    
}
extension NewHabitViewController {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text else { return true }

        let newLength = currentText.count + string.count - range.length
        return newLength <= 38
    }
}

extension NewHabitViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .emoji:
            return emojis.count
        case .color:
            return colors.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }
        switch section {
        case .emoji:
           guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmojiCell.reuseIdentifier,
                for: indexPath
           ) as? EmojiCell else { return UICollectionViewCell() }
            
            let isSelected = indexPath.item == selectedEmojiIndex
            cell.configure(with: emojis[indexPath.item], isSelected: isSelected)
            return cell
        case .color:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColorCell.reuseIdentifier,
                for: indexPath
            ) as? ColorCell else { return UICollectionViewCell() }
            let isSelected = indexPath.item == selectedColorIndex
            cell.configure(with: colors[indexPath.item], isSelected: isSelected)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader, let section = Section(rawValue: indexPath.section) else {
            return UICollectionReusableView()
        }
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderView.reuseIdentifier, for: indexPath) as? HeaderView else { return UICollectionReusableView() }
        header.configure(with: section.title)
        return header
    }
}

extension NewHabitViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .emoji:
            selectedEmojiIndex = indexPath.item
            collectionView.reloadSections(IndexSet(integer: Section.emoji.rawValue))
        case .color:
            selectedColorIndex = indexPath.item
            collectionView.reloadSections(IndexSet(integer: Section.color.rawValue))
        }
        conditionCreateButton()
    }
}

final class EmojiCell: UICollectionViewCell {
    static let reuseIdentifier = "EmojiCell"
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
    }
    func configure(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        contentView.backgroundColor = isSelected ? .appLightGray : .clear
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        emojiLabel.text = nil
        contentView.backgroundColor = .clear
    }
    
}

final class ColorCell: UICollectionViewCell {
    static let reuseIdentifier = "ColorCell"
    
    private lazy var colorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(colorView)
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 40),
            colorView.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
    }
    
    func configure(with color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        
        if isSelected {
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        } else {
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        colorView.backgroundColor = nil
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = nil
    }
}

final class HeaderView: UICollectionReusableView {
    static let reuseIdentifier = "Header"
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = .appBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
       addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
        
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}
