import UIKit

class CDBaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
        setNavigationBarHidden(true, animated: false)
    }

    override func pushViewController(_ mrViewController: UIViewController, animated: Bool) {
        if viewControllers.count > 0 {
            mrViewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(mrViewController, animated: animated)
    }

    override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CDBaseNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
