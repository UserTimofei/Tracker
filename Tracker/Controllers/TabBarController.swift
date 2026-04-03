import UIKit

final class TabBarController: UITabBarController {
    
    private var topDivider: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTopDividerToBar()
        
        let store = AppDependencies.shared.makeTrackerStore()
        let recordStore = AppDependencies.shared.makeRecordStore()
        let homeVC = TrackersViewController(store: store, recordStore: recordStore)
        let statsVC = StatisticsViewController(recordStore: recordStore)
        
        let homeNav = UINavigationController(rootViewController: homeVC)
        let statsNav = UINavigationController(rootViewController: statsVC)
        
        homeVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tabbar.trackers", comment: "Trackers tab"),
            image: .recordCircleFill,
            selectedImage: nil
        )
        
        statsVC.tabBarItem = UITabBarItem(
            title:  NSLocalizedString("tabbar.statistics", comment: "Statistics tab"),
            image: .hareFill,
            selectedImage: nil
        )
        
        viewControllers = [homeNav, statsNav]
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
