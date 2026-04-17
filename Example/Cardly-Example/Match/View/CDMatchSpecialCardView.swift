import UIKit

/// 特殊卡片 — 完善资料提示卡
final class CDMatchSpecialCardView: UIView {

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.text = "Complete Your Profile"
        label.font = .systemFont(ofSize:22)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add more photos to get 3x more matches!"
        label.font = .systemFont(ofSize:16)
        label.textColor = UIColor(hex: 0x9CA3AF)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Complete Now", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize:16)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hex: 0x6366F1)
        btn.layer.cornerRadius = 25
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor(hex: 0x16161A)
        layer.cornerRadius = 16
        clipsToBounds = true

        addSubview(iconLabel)
        addSubview(subtitleLabel)
        addSubview(actionButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let centerY = bounds.midY - 40
        iconLabel.frame = CGRect(x: 30, y: centerY - 30, width: bounds.width - 60, height: 60)
        subtitleLabel.frame = CGRect(x: 30, y: iconLabel.frame.maxY + 12, width: bounds.width - 60, height: 50)
        actionButton.frame = CGRect(x: 40, y: subtitleLabel.frame.maxY + 24, width: bounds.width - 80, height: 50)
    }
}
