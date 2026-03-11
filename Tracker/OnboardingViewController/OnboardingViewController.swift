import UIKit

final class OnboardingViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var pages: [UIViewController] = []
    
    lazy var onboarding1: UIViewController = {
        let vc = UIViewController()
        let image1 = UIImageView(image: .onboarding1)
        image1.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(image1)
        NSLayoutConstraint.activate([
            image1.topAnchor.constraint(equalTo: vc.view.topAnchor),
            image1.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            image1.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            image1.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])
        
        return vc
    }()
    
    lazy var labelVC1: UILabel = {
        let label = UILabel()
        label.text = "Отслеживайте только \n то, что хотите"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .appBlack
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
        ])
        return label
    }()
    
    lazy var onboarding2: UIViewController = {
        let vc = UIViewController()
        let image2 = UIImageView(image: .onboarding2)
        image2.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(image2)
        NSLayoutConstraint.activate([
            image2.topAnchor.constraint(equalTo: vc.view.topAnchor),
            image2.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            image2.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            image2.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])
        return vc
    }()
    
    lazy var labelVC2: UILabel = {
        let label = UILabel()
        label.text = "Даже если это \n не литры воды и йога"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .appBlack
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()
    
    lazy var pageControl: UIPageControl = {
        
        let pageControl = UIPageControl()
        
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        
        pageControl.currentPageIndicatorTintColor = .appBlack
        pageControl.pageIndicatorTintColor = .appBlack.withAlphaComponent(0.3)
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    lazy var onboardingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Вот это технологии!", for: .normal)
        button.backgroundColor = .appBlack
        button.setTitleColor(.appWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onboardingButtonTapped), for: .touchUpInside)

        return button
    }()
   
    override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey : Any]? = nil) {
            super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        pages.append(onboarding1)
        pages.append(onboarding2)
        
        
        view.addSubview(onboardingButton)
        view.addSubview(pageControl)
        
        onboarding1.view.addSubview(labelVC1)
        onboarding2.view.addSubview(labelVC2)
       
        NSLayoutConstraint.activate([
            onboardingButton.heightAnchor.constraint(equalToConstant: 60),
            onboardingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            onboardingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            onboardingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
     
             pageControl.bottomAnchor.constraint(equalTo: onboardingButton.topAnchor, constant: -24),
             pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
  
            labelVC1.centerXAnchor.constraint(equalTo: onboarding1.view.safeAreaLayoutGuide.centerXAnchor),
            labelVC1.centerYAnchor.constraint(equalTo: onboarding1.view.safeAreaLayoutGuide.centerYAnchor),
  
            labelVC2.centerXAnchor.constraint(equalTo: onboarding2.view.safeAreaLayoutGuide.centerXAnchor),
            labelVC2.centerYAnchor.constraint(equalTo: onboarding2.view.safeAreaLayoutGuide.centerYAnchor),
        ])
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        delegate = self
        
        dataSource = self
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
    }
    
    @objc private func onboardingButtonTapped() {
        
        UserDefaults.standard.set(true, forKey: "onboardingWasShown")
        
        let tabBC = TabBarController()
        tabBC.modalPresentationStyle = .fullScreen
        present(tabBC, animated: true)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return pages.last
        }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex + 1
        
        guard previousIndex < pages.count else {
            return pages.first
        }
        
        return pages[previousIndex]
    }
}
    
