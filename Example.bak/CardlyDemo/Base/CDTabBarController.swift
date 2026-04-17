import UIKit

class CDTabBarController: UITabBarController {

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.92, blue: 0.0, alpha: 1.0) // 黄色
        view.layer.cornerRadius = 16
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBarAppearance()
        setupIndicator()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - Setup

    private func setupTabs() {
        let homeVC = CDMatchViewController()
        let profileVC = UIViewController()

        profileVC.view.backgroundColor = .white

        let tabs: [(UIViewController, String, String)] = [
            (homeVC,    "Home",    "house.fill"),
            (profileVC, "Profile", "person.fill"),
        ]

        viewControllers = tabs.map { vc, title, iconName in
            let icon = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate)
            vc.tabBarItem = UITabBarItem(title: title, image: icon, selectedImage: icon)
            return CDBaseNavigationController(rootViewController: vc)
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: 0xF8F9FA)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        // 未选中态
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.init(hex: 0x5F6368),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        // 选中态
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(hex: 0x202124),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func setupIndicator() {
        tabBar.addSubview(indicatorView)
        tabBar.sendSubviewToBack(indicatorView)
    }


}


