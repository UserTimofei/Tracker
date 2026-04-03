//
//  ScheduleCell.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 22.03.2026.
//
import UIKit

final class ScheduleCell: UITableViewCell {
    static let reuseIdentifier = "ScheduleCell"
    
    private let separatorView = UIView()
    var onToggle: ((Bool) -> Void)?
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.textColor = .appBlack
        title.translatesAutoresizingMaskIntoConstraints = false
        
        return title
    }()
    
    private lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.onTintColor = .appBlue
        
        return switchControl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(switchControl)
        
        separatorView.backgroundColor = .appGray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant:  -16),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    func configure(with day: WeekDay, isSelected: Bool, onToggle: @escaping (Bool) -> Void, isLast: Bool = false) {
        titleLabel.text = day.title
        switchControl.isOn = isSelected
        self.onToggle = onToggle
        
        separatorView.isHidden = isLast
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        onToggle?(sender.isOn)
    }
}
