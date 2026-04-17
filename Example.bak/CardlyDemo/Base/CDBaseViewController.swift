import UIKit

class CDBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.init(hex: 0xF8F9FA)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
