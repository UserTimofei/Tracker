//
//  TrackerCell.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 24.01.2026.
//
import UIKit

class TrackerCell: UICollectionViewCell {
    
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
            buttonStack.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor)
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
        isCompleted: Bool,
        isFutureDate: Bool,
        numbersOfCompletedTrackers: Int,
        onToggle: ((Bool) -> Void)? = nil) {
            
            self.tracker = tracker
            self.isCompleted = isCompleted
            self.completionCount = numbersOfCompletedTrackers
            self.onToggle = onToggle
            
                    
            let color = tracker.color
            coloredContainer.backgroundColor = color
            
            completeButton.backgroundColor = color
            completeButton.tintColor = .white
            
            let word = declinationOfDays(numbersOfCompletedTrackers)
            counterLabel.text = "\(numbersOfCompletedTrackers) \(word)"
            
            emojiLabel.text = tracker.emoji
            titleLabelCell.text = tracker.name
            
            completeButton.isSelected = isCompleted
            
            if isFutureDate {
                completeButton.alpha = 0.5
            } else {
                completeButton.alpha = isCompleted ? 0.6 : 1.0
            }
    }
    
    
    private func declinationOfDays(_ count: Int) -> String {
        
        let lastTwoDigits = count % 100
        
        if (11...14).contains(lastTwoDigits) {
            return "дней"
        }
        
        switch count % 10 {
        case 1:
            return "день"
        case 2, 3, 4:
            return "дня"
        default:
            return "дней"
        }
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
        completeButton.isSelected = false
        completeButton.isEnabled = true
        contentView.alpha = 1.0
    }
}
