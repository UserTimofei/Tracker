import UIKit

extension NSNotification.Name {
    static let trackerRecordsDidUpdate = NSNotification.Name("trackerRecordsDidUpdate")
}

final class StatisticsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var emptyStateView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let starImage = UIImageView(image: .appErrorStatistic)
        starImage.tintColor = .appGray
        starImage.contentMode = .scaleAspectFit
        starImage.widthAnchor.constraint(equalToConstant: 80).isActive = true
        starImage.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let labelTextError = UILabel()
        labelTextError.translatesAutoresizingMaskIntoConstraints = false
        labelTextError.text = NSLocalizedString("statistics.empty.title", comment: "Empty state title")
        labelTextError.numberOfLines = 1
        labelTextError.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        labelTextError.textColor = .appBlack
        labelTextError.textAlignment = .center
        
        stack.addArrangedSubview(starImage)
        stack.addArrangedSubview(labelTextError)
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])
        
        return container
    }()
    
    private lazy var statsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.layer.cornerRadius = 16
        stack.backgroundColor = .clear
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Properties
    
    private let recordStore: RecordStoreProtocol
    private var statisticsData: StatisticsModel?
    
    init(recordStore: RecordStoreProtocol) {
        self.recordStore = recordStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("tabbar.statistics", comment: "Statistics tab")
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordsDidUpdate),
            name: .trackerRecordsDidUpdate,
            object: nil
        )
        
        setupUI()
        loadStatistics()
    }
    
    
    @objc private func recordsDidUpdate() {
        loadStatistics()
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        view.backgroundColor = .appWhite
        
        view.addSubview(emptyStateView)
        view.addSubview(statsContainerView)
        statsContainerView.addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            statsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            statsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statsContainerView.heightAnchor.constraint(equalToConstant: 396),
            
            statsStackView.topAnchor.constraint(equalTo: statsContainerView.topAnchor),
            statsStackView.leadingAnchor.constraint(equalTo: statsContainerView.leadingAnchor),
            statsStackView.trailingAnchor.constraint(equalTo: statsContainerView.trailingAnchor),
            statsStackView.bottomAnchor.constraint(equalTo: statsContainerView.bottomAnchor)
        ])
    }
    
    private func loadStatistics() {
        do {
            let allRecords = try recordStore.fetchAllRecords()
            
            let bestPeriod = calculateBestPeriod(records: allRecords)
            let perfectDays = calculatePerfectDays(records: allRecords)
            let completedCount = calculateCompletedTrackersCount(records: allRecords)
            let averageValue = calculateAverageCompletion(records: allRecords)
            
            statisticsData = StatisticsModel(
                bestPeriod: bestPeriod,
                perfectDays: perfectDays,
                completedTrackers: completedCount,
                averageValue: averageValue
            )
            
            updateUI(for: statisticsData)
            
        } catch {
            print("❌ Ошибка загрузки статистики: \(error)")
            statisticsData = nil
            updateUI(for: nil)
        }
    }
    
    private func updateUI(for data: StatisticsModel?) {
        if let data = data, !data.isEmpty {
            emptyStateView.isHidden = true
            statsContainerView.isHidden = false
 
            statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            let cards = [
                createCard(title: NSLocalizedString("statistics.best_period", comment: "Best period"), value: "\(data.bestPeriod)"),
                createCard(title: NSLocalizedString("statistics.perfect_days", comment: "Perfect days"), value: "\(data.perfectDays)"),
                createCard(title: NSLocalizedString("statistics.completed_trackers", comment: "Completed trackers"), value: "\(data.completedTrackers)"),
                createCard(title: NSLocalizedString("statistics.average_value", comment: "Average value"), value: "\(data.averageValue)")
            ]

            for card in cards {
                statsStackView.addArrangedSubview(card)
            }

            view.setNeedsLayout()
            view.layoutIfNeeded()

            let colors: [CGColor] = [
                UIColor.appRedStatistic.cgColor,
                UIColor.appGreenStatistic.cgColor,
                UIColor.appBlueStatistic.cgColor
            ]
            
            for card in cards {
                card.addGradientBorder(colors: colors, borderWidth: 2)
            }
            
        } else {
            emptyStateView.isHidden = false
            statsContainerView.isHidden = true
        }
    }
    
    // MARK: - Helpers
    
    private func createCard(title: String, value: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.clipsToBounds = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .appBlack
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(titleLabel)
        card.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            valueLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            
            card.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        return card
    }
}

// MARK: - Logic Helpers

struct StatisticsModel {
    let bestPeriod: Int
    let perfectDays: Int
    let completedTrackers: Int
    let averageValue: Int
    
    var isEmpty: Bool {
        return bestPeriod == 0 && perfectDays == 0 && completedTrackers == 0 && averageValue == 0
    }
}

extension StatisticsViewController {
    
    private func calculateBestPeriod(records: [TrackerRecord]) -> Int {
        guard records.count > 0 else { return 0 }
        
        var dates = Set<Date>()
        for record in records {
            let startOfDay = Calendar.current.startOfDay(for: record.date)
            dates.insert(startOfDay)
        }
        
        let sortedDates = dates.sorted()
        
        var maxStreak = 0
        var currentStreak = 0
        
        for i in 0..<sortedDates.count {
            if i == 0 {
                currentStreak = 1
            } else {
                let prevDate = sortedDates[i-1]
                let currDate = sortedDates[i]
                
                let calendar = Calendar.current
                if calendar.isDate(currDate, equalTo: prevDate, toGranularity: .day) {
                    continue
                }
                
                let oneDayLater = calendar.date(byAdding: .day, value: 1, to: prevDate) ?? Date()
                if calendar.isDate(currDate, equalTo: oneDayLater, toGranularity: .day) {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            }
        }
        maxStreak = max(maxStreak, currentStreak)
        
        return maxStreak
    }
    
    private func calculatePerfectDays(records: [TrackerRecord]) -> Int {
        guard records.count > 0 else { return 0 }
        
        var uniqueDates = Set<Date>()
        for record in records {
            uniqueDates.insert(Calendar.current.startOfDay(for: record.date))
        }
        
        return uniqueDates.count
    }
    
    private func calculateCompletedTrackersCount(records: [TrackerRecord]) -> Int {
        return records.count
    }
    
    private func calculateAverageCompletion(records: [TrackerRecord]) -> Int {
        guard records.count > 0 else { return 0 }
        
        var uniqueDates = Set<Date>()
        for record in records {
            uniqueDates.insert(Calendar.current.startOfDay(for: record.date))
        }
        
        guard uniqueDates.count > 0 else { return 0 }
        
        let average = Double(records.count) / Double(uniqueDates.count)
        return Int(average.rounded(.up))
    }
}

extension UIView {
    
    func addGradientBorder(
        colors: [CGColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1),
        borderWidth: CGFloat = 2
    ) {

        self.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

        self.layer.borderWidth = 0
        self.clipsToBounds = false
        self.layer.masksToBounds = false

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = colors
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.cornerRadius = self.layer.cornerRadius

        let maskLayer = CAShapeLayer()
        maskLayer.lineWidth = borderWidth
        maskLayer.fillColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.white.cgColor
        maskLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        
        gradientLayer.mask = maskLayer

        self.layer.addSublayer(gradientLayer)
    }
    
    func updateGradientBorder() {
        guard let gradientLayer = self.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer else {
            return
        }
        
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = self.layer.cornerRadius
        
        if let maskLayer = gradientLayer.mask as? CAShapeLayer {
            maskLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        }
    }
}
