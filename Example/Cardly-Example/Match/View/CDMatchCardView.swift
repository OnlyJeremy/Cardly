import UIKit

final class CDMatchCardView: UIView {

    // MARK: - UI Elements

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        layer.locations = [0.5, 1.0]
        return layer
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize:24)
        label.textColor = .white
        return label
    }()

    private let ageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize:18)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize:14)
        label.textColor = .white.withAlphaComponent(0.7)
        return label
    }()

    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize:14)
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 2
        return label
    }()


    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor(hex: 0x16161A)
        layer.cornerRadius = 16
        clipsToBounds = true

        addSubview(backgroundImageView)
        layer.addSublayer(gradientLayer)
        addSubview(nameLabel)
        addSubview(ageLabel)
        addSubview(distanceLabel)
        addSubview(bioLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundImageView.frame = bounds
        gradientLayer.frame = bounds

        let padding: CGFloat = 20
        let bottom = bounds.height - padding

        bioLabel.frame = CGRect(x: padding, y: bottom - 20, width: bounds.width - padding * 2, height: 20)
        bioLabel.sizeToFit()
        bioLabel.frame.origin.y = bottom - bioLabel.frame.height

        distanceLabel.frame = CGRect(x: padding, y: bioLabel.frame.minY - 24, width: bounds.width - padding * 2, height: 20)

        let ageSize = ageLabel.sizeThatFits(CGSize(width: 100, height: 30))
        let nameSize = nameLabel.sizeThatFits(CGSize(width: bounds.width - padding * 2 - ageSize.width - 12, height: 30))

        nameLabel.frame = CGRect(x: padding, y: distanceLabel.frame.minY - 32, width: nameSize.width, height: 30)
        ageLabel.frame = CGRect(x: nameLabel.frame.maxX + 8, y: nameLabel.frame.minY + 2, width: ageSize.width, height: 26)

    }

    // MARK: - Configure

    func configure(with card: CDMatchUserCard) {
        nameLabel.text = card.nickname
        ageLabel.text = "\(card.age)"
        distanceLabel.text = card.distance
        bioLabel.text = card.bio

        // Mock: use gradient colors as placeholder for avatar
        let colors: [UIColor] = [
            UIColor(hex: 0x6366F1), UIColor(hex: 0x8B5CF6), UIColor(hex: 0xEC4899),
            UIColor(hex: 0x14B8A6), UIColor(hex: 0xF59E0B), UIColor(hex: 0x3B82F6),
            UIColor(hex: 0x10B981), UIColor(hex: 0xEF4444), UIColor(hex: 0x6366F1)
        ]
        let color = colors[abs(card.userID) % colors.count]
        backgroundImageView.image = nil
        backgroundImageView.backgroundColor = color
    }

}
