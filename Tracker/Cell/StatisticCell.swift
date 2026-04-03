//
//  StatisticCell.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 22.03.2026.
//

import UIKit

final class StatisticCell: UITableViewCell {
    static let reuseIdentifier = "StatisticCell"
    
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    // Для градиентной рамки используем CALayer
    private let gradientLayer = CAGradientLayer()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // Убираем подсветку при нажатии
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .systemBackground
        
        // Настройка заголовка
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Настройка значения
        valueLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
        // Настройка градиентной рамки
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.cornerRadius = 12
        gradientLayer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Градиент должен занимать всю область ячейки + отступы
        gradientLayer.frame = bounds.insetBy(dx: -1.5, dy: -1.5) // -1.5 для толщины рамки
        gradientLayer.colors = [UIColor.systemRed.cgColor, UIColor.systemGreen.cgColor, UIColor.systemBlue.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }
    
    func configure(with title: String, value: Int) {
        titleLabel.text = title
        valueLabel.text = "\(value)"
    }
}
