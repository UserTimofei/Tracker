//
//  TabBarController.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 14.01.2026.
//

import UIKit

final class TabBarController: UITabBarController {
    
    private var topDivider: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTopDividerToBar()
        
        let homeVC = HomeViewController()
        let statsVC = StatisticsViewController()
        
        let homeNav = UINavigationController(rootViewController: homeVC)
        let statsNav = UINavigationController(rootViewController: statsVC)
        
        homeVC.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: .recordCircleFill,
            selectedImage: nil
        )
        
        statsVC.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: .hareFill,
            selectedImage: nil
        )
        
        viewControllers = [homeVC, statsVC]
        
    }
    
    private func addTopDividerToBar() {
        let divider = UIView()
        divider.backgroundColor = .appGray
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        tabBar.addSubview(divider)
        
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: tabBar.topAnchor),
            divider.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        
        topDivider = divider
    }
    
    
}
