//
//  ViewController.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 13.01.2026.
//

import UIKit

class HomeViewController: UIViewController {
    
    lazy var viewHeight = createView(backgroundColor: .appWhite, radius: 0)
       
    
    lazy var viewBtnAdd: UIView = {
        $0.backgroundColor = .appWhite
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView())
    
    lazy var btnAddButton: UIButton = {
        $0.setImage(.plusDark, for: .normal)
        $0.tintColor = .appBack
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton(primaryAction: btnActionAdd))
    
    lazy var btnActionAdd: UIAction = UIAction { [weak self] _ in
        
    }
    
    lazy var labelTrecker = createLabel(text: "Трекеры", fontOfSize: 34, textColor: .appBack, style: .bold, radius: 0, backgroundColor: .appWhite)
    
    
    lazy var dateLabel = createLabel(
        text: Service().formatterDate(),
        fontOfSize: 17,
        textColor: .appBack,
        style: .regular,
        radius: 8,
        backgroundColor: .appGrayDate
    )
    
    lazy var labelTextError = createLabel(text: "Что будем отслеживать?", fontOfSize: 12, textColor: .appBack, style: .medium, radius: 0, backgroundColor: .appWhite)
    
    lazy var searchBar: UISearchBar = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.placeholder = "Поиск"
        $0.tintColor = .appGray
        $0.barTintColor = .appSearch
//        $0.backgroundColor = .appSearch
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        
        return $0
    }(UISearchBar())
    
    
    
    
    
    lazy var imageError = createImageView(image: .appError)

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appWhite
        
        view.addSubview(viewHeight)
        view.addSubview(imageError)
        viewHeight.addSubview(viewBtnAdd)
        viewBtnAdd.addSubview(btnAddButton)
        viewHeight.addSubview(labelTrecker)
        viewHeight.addSubview(dateLabel)
        viewHeight.addSubview(searchBar)
        view.addSubview(labelTextError)
        
        
        
        NSLayoutConstraint.activate([
            viewHeight.topAnchor.constraint(equalTo: view.topAnchor),
            viewHeight.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewHeight.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewHeight.heightAnchor.constraint(equalToConstant: 182),
            
            viewBtnAdd.heightAnchor.constraint(equalToConstant: 42),
            viewBtnAdd.widthAnchor.constraint(equalToConstant: 42),
            viewBtnAdd.topAnchor.constraint(equalTo: viewHeight.topAnchor, constant: 45),
            viewBtnAdd.leadingAnchor.constraint(equalTo: viewHeight.leadingAnchor, constant: 6),
            
            btnAddButton.centerXAnchor.constraint(equalTo: viewBtnAdd.centerXAnchor),
            btnAddButton.centerYAnchor.constraint(equalTo: viewBtnAdd.centerYAnchor),
            
            labelTrecker.topAnchor.constraint(equalTo: viewHeight.topAnchor, constant: 88),
            labelTrecker.leadingAnchor.constraint(equalTo: viewHeight.leadingAnchor, constant: 16),
            labelTrecker.trailingAnchor.constraint(equalTo: viewHeight.trailingAnchor, constant: 105),
            labelTrecker.heightAnchor.constraint(equalToConstant: 41),
            
            dateLabel.topAnchor.constraint(equalTo: viewHeight.topAnchor, constant: 49),
            dateLabel.trailingAnchor.constraint(equalTo: viewHeight.trailingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(equalTo: viewHeight.bottomAnchor, constant: -99),
            
            searchBar.topAnchor.constraint(equalTo: labelTrecker.bottomAnchor, constant: 6),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            searchBar.leadingAnchor.constraint(equalTo: viewHeight.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: viewHeight.trailingAnchor, constant: -16),
            
            imageError.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageError.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            labelTextError.topAnchor.constraint(equalTo: imageError.bottomAnchor, constant: 8),
            labelTextError.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            
            
        ])
        
    }
    
    func createView(backgroundColor: UIColor, radius: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = radius
        view.clipsToBounds = true
        
        return view
    }
    
    func createLabel(text: String, fontOfSize: CGFloat, textColor: UIColor, style: UIFont.Weight, radius: CGFloat, backgroundColor: UIColor ) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = backgroundColor
        label.text = text
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: fontOfSize, weight: style)
        label.textColor = textColor
        label.layer.cornerRadius = radius
        label.clipsToBounds = true
        
        return label
    }
    
    func createImageView(image: UIImage) -> UIImageView {
        {
            $0.image = image
            $0.translatesAutoresizingMaskIntoConstraints = false
            
            return $0
        }(UIImageView())
    }

}

