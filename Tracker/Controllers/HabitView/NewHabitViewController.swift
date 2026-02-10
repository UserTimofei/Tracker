//
//  NewHabitViewController.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 27.01.2026.
//

import UIKit
class NewHabitViewController: UIViewController, UITextFieldDelegate {
    
    var onSave: ((Tracker, String) -> Void)?
    private var selectedSchedule: Set<WeekDay> = []
    private var categoryTitleLabel: UILabel?
    
    private var categoryButtonTopWhenErrorHidden: NSLayoutConstraint!
    private var categoryButtonTopWhenErrorVisible: NSLayoutConstraint!
    private var scheduleDisplayText: String {
        if selectedSchedule.count == WeekDay.allCases.count {
            return "Каждый день"
        } else {
            let sortedDays = selectedSchedule.sorted { $0.calendarWeekDay < $1.calendarWeekDay }
            return sortedDays.map { $0.shortTitle }.joined(separator: ", ")
        }
    }
    private let availableCategories = ["Полезные привычки", "Личностный рост", "Здоровье", "Учёба"]
    private var selectedCategory: String = "Важное" // ← теперь по умолчанию "Важное"
    
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

    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .appGray
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle("Создать", for: .normal)
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
        navigationItem.title = "Новая привычка"
        view.backgroundColor = .appWhite
        setupUI()
        conditionCreateButton()
        updateCategoryButtonTitle()
        
    }
    
    private func setupUI() {
        view.addSubview(textField)
        view.addSubview(errorLabel)
        categoryScheduleBlock.backgroundColor = .appBackground
        view.addSubview(categoryScheduleBlock)
        
        categoryScheduleBlock.addSubview(categoryButton)
        categoryScheduleBlock.addSubview(scheduleButton)
        categoryScheduleBlock.addSubview(dividerView)
        
        textField.inputAccessoryView = keyboardToolbar
        
        let stackBottomButton = UIStackView()
        stackBottomButton.axis = .horizontal
        stackBottomButton.spacing = 8
        stackBottomButton.distribution = .fillEqually
        stackBottomButton.translatesAutoresizingMaskIntoConstraints = false
        
        stackBottomButton.addArrangedSubview(cancelButton)
        stackBottomButton.addArrangedSubview(createButton)
        view.addSubview(stackBottomButton)

        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always

        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.rightView = rightPaddingView
        textField.rightViewMode = .always
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 75),
            
            errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            errorLabel.heightAnchor.constraint(equalToConstant: 20),
            
            categoryScheduleBlock.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryScheduleBlock.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryScheduleBlock.heightAnchor.constraint(equalToConstant: 150.5),
            scheduleButton.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -24),
            
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
            
            stackBottomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackBottomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackBottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackBottomButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        categoryButtonTopWhenErrorHidden = categoryButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24)
        categoryButtonTopWhenErrorVisible = categoryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 32)
        
        categoryButtonTopWhenErrorHidden.isActive = true
    }
    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }
    
    @objc private func addTapCategory() {
        
    }
    @objc private func createButtonTapped() {
        guard let name = textField.text, !name.isEmpty else { return }
        
        let category = selectedCategory ?? availableCategories.first
        
        let newTracker = Tracker(id: UUID(), name: name, color: .appColorSelection1, emoji: "✅", schedule: selectedSchedule)
        onSave?(newTracker, selectedCategory)
        
        dismiss(animated: true)
    }
    
    @objc private func addTapSchedule() {
        let newScheduleVC = ScheduleVC()
        
        newScheduleVC.selectedDays = selectedSchedule
        newScheduleVC.onSave = { [weak self] days in
            guard let self = self else { return }
            self.selectedSchedule = Set(days)
            updateScheduleButtonTitle()
            conditionCreateButton()
        }
        navigationController?.pushViewController(newScheduleVC, animated: true)
    }
    
    private func updateScheduleButtonTitle() {
        let displayText = scheduleDisplayText
        
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
        }
    }
    
    private func updateCategoryButtonTitle() {
        let titleText = selectedCategory ?? "Категория"
        
        let fullTest = "Категория\n\(titleText)"
        
        let attributed = NSMutableAttributedString(string: fullTest)
        
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

        let isValid = hasName && hasSchedule
        
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
        
        categoryButtonTopWhenErrorHidden.isActive = !isOverLimit
        categoryButtonTopWhenErrorVisible.isActive = isOverLimit
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
