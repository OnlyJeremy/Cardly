import UIKit
import Cardly

/// 业务层的拖拽叠层 — 继承 CardlyOverlayView
/// CardlyView 拖拽时自动调用 update/reset，业务层无需在 delegate 中手动操作
final class CDMatchOverlayView: CardlyOverlayView {

    private let likeLabel: UILabel = {
        let label = UILabel()
        label.text = "LIKE"
        label.font = .systemFont(ofSize:40)
        label.textColor = UIColor(hex: 0x4ADE80)
        label.textAlignment = .center
        label.alpha = 0
        label.transform = CGAffineTransform(rotationAngle: -.pi / 8)
        label.layer.borderColor = UIColor(hex: 0x4ADE80).cgColor
        label.layer.borderWidth = 4
        label.layer.cornerRadius = 8
        return label
    }()

    private let nopeLabel: UILabel = {
        let label = UILabel()
        label.text = "NOPE"
        label.font = .systemFont(ofSize:40)
        label.textColor = UIColor(hex: 0xEF4444)
        label.textAlignment = .center
        label.alpha = 0
        label.transform = CGAffineTransform(rotationAngle: .pi / 8)
        label.layer.borderColor = UIColor(hex: 0xEF4444).cgColor
        label.layer.borderWidth = 4
        label.layer.cornerRadius = 8
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(likeLabel)
        addSubview(nopeLabel)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        likeLabel.frame = CGRect(x: 20, y: 40, width: 150, height: 60)
        nopeLabel.frame = CGRect(x: bounds.width - 170, y: 40, width: 150, height: 60)
    }

    override func update(progress: CGFloat, direction: CardlySwipeDirection) {
        switch direction {
        case .right:
            likeLabel.alpha = progress
            nopeLabel.alpha = 0
        case .left:
            nopeLabel.alpha = progress
            likeLabel.alpha = 0
        }
    }

    override func reset() {
        likeLabel.alpha = 0
        nopeLabel.alpha = 0
    }
}
