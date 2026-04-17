# Cardly

[![CocoaPods](https://img.shields.io/cocoapods/v/Cardly.svg?style=flat)](https://cocoapods.org/pods/Cardly)
[![CocoaPods](https://img.shields.io/cocoapods/p/Cardly.svg?style=flat)](https://cocoapods.org/pods/Cardly)
[![License](https://img.shields.io/cocoapods/l/Cardly.svg?style=flat)](https://github.com/OnlyJeremy/Cardly/blob/main/LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://github.com/OnlyJeremy/Cardly)

高性能卡片堆叠容器 UI 组件，灵感来自 Tinder 和 Koloda。

## 特性

- 📱 流畅的手势拖拽交互
- ⚙️ 可配置的动画参数
- 🎨 支持自定义 Overlay（LIKE/NOPE 效果）
- 📦 预加载和批量操作
- 🚀 零第三方依赖

## 要求

- iOS 14.0+
- Swift 5.0+

## 安装

### CocoaPods

```ruby
pod 'Cardly', '~> 1.0'
```

## 快速开始

### 1. 基础设置

```swift
import UIKit
import Cardly

class ViewController: UIViewController {
    let cardlyView = CardlyView()
    var cards: [CardModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 配置 CardlyView
        cardlyView.dataSource = self
        cardlyView.delegate = self
        cardlyView.visibleCardCount = 2          // 同时显示的卡片数
        cardlyView.prefetchThreshold = 5         // 剩余5张时触发预加载
        cardlyView.isSwipeEnabled = true         // 启用手势拖拽
        
        view.addSubview(cardlyView)
        cardlyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
```

### 2. 实现 DataSource 协议

```swift
extension ViewController: CardlyViewDataSource {
    
    // 返回卡片总数
    func numberOfCards(in cardlyView: CardlyView) -> Int {
        return cards.count
    }
    
    // 返回指定索引的卡片视图
    func cardlyView(_ cardlyView: CardlyView, viewForCardAt index: Int) -> UIView {
        let cardView = CardView()
        cardView.configure(with: cards[index])
        return cardView
    }
    
    // 返回指定索引的叠层视图（可选）
    func cardlyView(_ cardlyView: CardlyView, overlayForCardAt index: Int) -> CardlyOverlayView? {
        return CustomOverlayView()
    }
}
```

### 3. 实现 Delegate 协议

```swift
extension ViewController: CardlyViewDelegate {
    
    // 卡片被滑走时调用
    func cardlyView(_ cardlyView: CardlyView, didSwipeCardAt index: Int, in direction: CardlySwipeDirection) {
        let action = direction == .left ? "NOPE" : "LIKE"
        print("用户\(action)了卡片 \(index)")
    }
    
    // 新卡片展示时调用
    func cardlyView(_ cardlyView: CardlyView, didShowCardAt index: Int) {
        print("展示卡片 \(index)")
    }
    
    // 卡片被移除时调用
    func cardlyView(_ cardlyView: CardlyView, didRemoveCardAt index: Int) {
        print("移除卡片 \(index)")
    }
    
    // 所有卡片用完时调用
    func cardlyViewDidRunOutOfCards(_ cardlyView: CardlyView) {
        print("没有更多卡片了")
    }
    
    // 拖拽进度变化时调用（用于震动反馈等）
    func cardlyView(_ cardlyView: CardlyView, draggingCardAt index: Int, progress: CGFloat, direction: CardlySwipeDirection) {
        if progress >= 0.2 {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    // 触发预加载时调用
    func cardlyView(_ cardlyView: CardlyView, needsPrefetchWithRemainingCount remaining: Int) {
        print("剩余\(remaining)张卡片，触发预加载")
        loadMoreCards()
    }
}
```

## API 参考

### 配置属性

```swift
// 同时可见的卡片数量（默认 2）
cardlyView.visibleCardCount = 2

// 剩余多少张时触发预加载回调（默认 5）
cardlyView.prefetchThreshold = 5

// 是否允许手势拖拽（默认 true）
cardlyView.isSwipeEnabled = true

// 当前展示卡片的索引（只读）
let index = cardlyView.currentCardIndex
```

### 卡片操作方法

```swift
// 代码触发滑动（带动画）
cardlyView.swipeCurrentCard(direction: .right)  // 右滑（喜欢）
cardlyView.swipeCurrentCard(direction: .left)   // 左滑（不喜欢）

// 移除当前卡片（缩小淡出动画）
cardlyView.removeCurrentCard()

// 移除指定索引的卡片
cardlyView.removeCard(at: 3)

// 按条件批量移除卡片
cardlyView.removeCards { index in
    return index > 10  // 移除索引 > 10 的卡片
}

// 在指定位置插入卡片（数据源需先更新）
cards.insert(newCard, at: 2)
cardlyView.insertCard(at: 2)

// 刷新指定卡片内容（用户修改后）
cardlyView.reloadCard(at: 2)
```

### 数据管理方法

```swift
// 重新加载所有卡片，保持当前位置
cardlyView.reloadData()

// 重新加载所有卡片，重置到第一张
cardlyView.reloadDataAndResetIndex()

// 追加新卡片（数据源先增加数据）
cards.append(contentsOf: newCards)
cardlyView.appendCards(count: newCards.count)
```

### 动画配置

```swift
let animator = cardlyView.animator

// 拖拽触发阈值（0~1，默认 0.4）
animator.swipeThreshold = 0.4

// 最大旋转角度（默认 π/8）
animator.maxRotationAngle = CGFloat.pi / 6

// 滑出动画时长（默认 0.3s）
animator.swipeOutDuration = 0.3

// 回弹动画时长（默认 0.25s）
animator.snapBackDuration = 0.25

// 下一张卡片放大时长（默认 0.2s）
animator.nextCardScaleDuration = 0.2

// 背景卡片缩放比例（默认 0.95）
animator.backgroundCardScale = 0.95

// 背景卡片垂直偏移（默认 12）
animator.backgroundCardVerticalOffset = 12
```

## 自定义 Overlay（LIKE/NOPE 效果）

继承 `CardlyOverlayView` 实现自定义拖拽叠层效果：

```swift
class CustomOverlayView: CardlyOverlayView {
    
    private let likeLabel = UILabel()
    private let nopeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 配置 LIKE 标签
        likeLabel.text = "LIKE"
        likeLabel.font = .systemFont(ofSize: 40, weight: .bold)
        likeLabel.textColor = .green
        likeLabel.alpha = 0
        likeLabel.transform = CGAffineTransform(rotationAngle: -.pi / 8)
        addSubview(likeLabel)
        
        // 配置 NOPE 标签
        nopeLabel.text = "NOPE"
        nopeLabel.font = .systemFont(ofSize: 40, weight: .bold)
        nopeLabel.textColor = .red
        nopeLabel.alpha = 0
        nopeLabel.transform = CGAffineTransform(rotationAngle: .pi / 8)
        addSubview(nopeLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        likeLabel.frame = CGRect(x: 20, y: 40, width: 150, height: 60)
        nopeLabel.frame = CGRect(x: bounds.width - 170, y: 40, width: 150, height: 60)
    }
    
    // 拖拽进度更新 — CardlyView 自动调用
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
    
    // 拖拽取消（回弹）时重置
    override func reset() {
        likeLabel.alpha = 0
        nopeLabel.alpha = 0
    }
}
```

## 完整示例：预加载 + 追加卡片

```swift
class MatchViewController: UIViewController {
    let cardlyView = CardlyView()
    var cards: [CardModel] = []
    let server = MatchServer.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardlyView.dataSource = self
        cardlyView.delegate = self
        cardlyView.prefetchThreshold = 5
        
        view.addSubview(cardlyView)
        
        // 首次加载数据
        loadInitialCards()
    }
    
    private func loadInitialCards() {
        server.fetchFirstPage { [weak self] cards in
            self?.cards = cards
            self?.cardlyView.reloadDataAndResetIndex()
        }
    }
    
    private func loadMoreCards() {
        server.fetchNextPage { [weak self] newCards in
            guard let self = self else { return }
            self.cards.append(contentsOf: newCards)
            self.cardlyView.appendCards(count: newCards.count)
        }
    }
}

extension MatchViewController: CardlyViewDataSource {
    func numberOfCards(in cardlyView: CardlyView) -> Int {
        return cards.count
    }
    
    func cardlyView(_ cardlyView: CardlyView, viewForCardAt index: Int) -> UIView {
        let cardView = MatchCardView()
        cardView.configure(with: cards[index])
        return cardView
    }
    
    func cardlyView(_ cardlyView: CardlyView, overlayForCardAt index: Int) -> CardlyOverlayView? {
        return CustomOverlayView()
    }
}

extension MatchViewController: CardlyViewDelegate {
    func cardlyView(_ cardlyView: CardlyView, needsPrefetchWithRemainingCount remaining: Int) {
        if remaining <= cardlyView.prefetchThreshold {
            loadMoreCards()
        }
    }
    
    // 其他回调...
}
```

## 许可证

Cardly 采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

