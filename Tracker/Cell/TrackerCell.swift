import UIKit

final class TrackerCell: UICollectionViewCell {
    
    static let reuseIdentifier = "TrackerCell"
    
    private lazy var coloredContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var buttonContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()

    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .appBlack
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var emojiLabelBackgroundView: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.appWhite.withAlphaComponent(0.3)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var titleLabelCell: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .appWhite
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var counterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .appBlack
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    private lazy var completeButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 17
        button.clipsToBounds = true
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "pin.fill")
        imageView.tintColor = .appWhite
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var tracker: Tracker?
    private var isCompleted = false
    private var completionCount = 0
    
    var onToggle: ((Bool) -> Void)?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        emojiLabelBackgroundView.addSubview(emojiLabel)
        contentView.addSubview(pinImageView)
        
        NSLayoutConstraint.activate([
            emojiLabelBackgroundView.widthAnchor.constraint(equalToConstant: 24),
            emojiLabelBackgroundView.heightAnchor.constraint(equalToConstant: 24),
            emojiLabel.centerXAnchor.constraint(equalTo: emojiLabelBackgroundView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiLabelBackgroundView.centerYAnchor)
        ])

        let setupImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        let plusImage = UIImage(systemName: "plus", withConfiguration: setupImage)
        let checkImage = UIImage(systemName: "checkmark", withConfiguration: setupImage)

        completeButton.setImage(plusImage, for: .normal)
        completeButton.setImage(checkImage, for: .selected)
        
        NSLayoutConstraint.activate([
            completeButton.widthAnchor.constraint(equalToConstant: 34),
            completeButton.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        let colorStack = UIStackView(arrangedSubviews: [emojiLabelBackgroundView, titleLabelCell])
        colorStack.axis = .vertical
        colorStack.spacing = 8
        colorStack.alignment = .leading
        colorStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        colorStack.isLayoutMarginsRelativeArrangement = true
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        
        coloredContainer.addSubview(colorStack)
        
        let buttonStack = UIStackView(arrangedSubviews: [counterLabel, completeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .center
        buttonStack.distribution = .fill
        buttonStack.layoutMargins = UIEdgeInsets(top: 16, left: 12, bottom: 12, right: 12)
        buttonStack.isLayoutMarginsRelativeArrangement = true
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        buttonContainer.addSubview(buttonStack)
        
        contentView.addSubview(coloredContainer)
        contentView.addSubview(buttonContainer)
        
        contentView.bringSubviewToFront(pinImageView)
        
        NSLayoutConstraint.activate([
            coloredContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            coloredContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coloredContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coloredContainer.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.6),
            
            buttonContainer.topAnchor.constraint(equalTo: coloredContainer.bottomAnchor),
            buttonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            colorStack.topAnchor.constraint(equalTo: coloredContainer.topAnchor),
            colorStack.bottomAnchor.constraint(equalTo: coloredContainer.bottomAnchor),
            colorStack.leadingAnchor.constraint(equalTo: coloredContainer.leadingAnchor),
            colorStack.trailingAnchor.constraint(equalTo: coloredContainer.trailingAnchor),
            
            buttonStack.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            
            pinImageView.topAnchor.constraint(equalTo: coloredContainer.topAnchor, constant: 18),
            pinImageView.trailingAnchor.constraint(equalTo: coloredContainer.trailingAnchor, constant: -12),
            pinImageView.widthAnchor.constraint(equalToConstant: 16),
            pinImageView.heightAnchor.constraint(equalToConstant: 24)
            ])
    }
    
    @objc private func toggleButtonTapped() {
        guard tracker != nil else { return }
        
        isCompleted.toggle()
        completeButton.isSelected = isCompleted
        completeButton.backgroundColor = tracker!.color
        onToggle?(isCompleted)
    }
    
    func configure(
        with tracker: Tracker,
        isPinned: Bool,
        isCompleted: Bool,
        isFutureDate: Bool,
        numbersOfCompletedTrackers: Int,
        onToggle: ((Bool) -> Void)? = nil) {
            
            print("📝 configure: счетчик установлен = \(numbersOfCompletedTrackers)")
            
            self.tracker = tracker
            self.isCompleted = isCompleted
            self.completionCount = numbersOfCompletedTrackers
            self.onToggle = onToggle
            
            print("🔧 TrackerCell.configure для \(tracker.name)")
            print("   onToggle есть: \(onToggle != nil ? "✅" : "❌")")
            print("   isPinned: \(isPinned)")
            
            let color = tracker.color
            coloredContainer.backgroundColor = color
            
            completeButton.backgroundColor = color
            completeButton.tintColor = .white
            
            let word = Self.declinationOfDays(numbersOfCompletedTrackers)
            counterLabel.text = word
            
            emojiLabel.text = tracker.emoji
            titleLabelCell.text = tracker.name
            
            completeButton.isSelected = isCompleted
            
            if isFutureDate {
                completeButton.alpha = 0.5
            } else {
                completeButton.alpha = isCompleted ? 0.6 : 1.0
            }
            
            pinImageView.isHidden = !isPinned
            pinImageView.tintColor = .white
            pinImageView.backgroundColor = .clear
            
            print("   pinImageView.isHidden: \(pinImageView.isHidden)")
            print("   pinImageView.image: \(pinImageView.image)")
        }
    
    func updateCounter(_ newCount: Int) {
        completionCount = newCount
        counterLabel.text = Self.declinationOfDays(newCount)
    }
    
    static func declinationOfDays(_ count: Int) -> String {
        let format = NSLocalizedString("days.count", comment: "Days count with plural form")
        let result = String.localizedStringWithFormat(format, count)

        print("🌍 Текущая локаль: \(Locale.current.identifier)")
        print("🔑 Сырая строка формата из bundles: '\(format)'")
        print("✅ Итоговый результат: '\(result)'")

        
        return result
    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        tracker = nil
        isCompleted = false
        completionCount = 0
        onToggle = nil
        
        coloredContainer.backgroundColor = nil
        emojiLabel.text = nil
        titleLabelCell.text = nil
        counterLabel.text = nil
        counterLabel.attributedText = nil
        completeButton.isSelected = false
        completeButton.isEnabled = true
        contentView.alpha = 1.0
    }
}
