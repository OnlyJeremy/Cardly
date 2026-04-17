# Cardly

[![CocoaPods](https://img.shields.io/cocoapods/v/Cardly.svg?style=flat)](https://cocoapods.org/pods/Cardly)
[![CocoaPods](https://img.shields.io/cocoapods/p/Cardly.svg?style=flat)](https://cocoapods.org/pods/Cardly)
[![License](https://img.shields.io/cocoapods/l/Cardly.svg?style=flat)](https://github.com/your-org/Cardly-iOS/blob/main/LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://github.com/your-org/Cardly-iOS)

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

## 使用

### 基础示例

```swift
import UIKit
import Cardly

class ViewController: UIViewController, CardlyViewDataSource, CardlyViewDelegate {
    @IBOutlet weak var cardlyView: CardlyView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardlyView.dataSource = self
        cardlyView.delegate = self
    }
    
    // MARK: - CardlyViewDataSource
    
    func numberOfCards(in cardlyView: CardlyView) -> Int {
        return 20
    }
    
    func cardlyView(_ cardlyView: CardlyView, viewForCardAt index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(hue: CGFloat(index) / 20.0, saturation: 0.8, brightness: 0.9, alpha: 1.0)
        return card
    }
    
    func cardlyView(_ cardlyView: CardlyView, overlayForCardAt index: Int) -> CardlyOverlayView? {
        return nil
    }
    
    // MARK: - CardlyViewDelegate
    
    func cardlyView(_ cardlyView: CardlyView, didSwipeCardAt index: Int, in direction: CardlySwipeDirection) {
        print("Swiped card \(index): \(direction == .left ? "NOPE" : "LIKE")")
    }
    
    func cardlyView(_ cardlyView: CardlyView, didShowCardAt index: Int) {
        print("Showing card \(index)")
    }
    
    func cardlyViewDidRunOutOfCards(_ cardlyView: CardlyView) {
        print("No more cards!")
    }
}
```

### 自定义动画参数

```swift
cardlyView.animator.swipeThreshold = 0.3
cardlyView.animator.swipeOutDuration = 0.4
cardlyView.animator.maxRotationAngle = CGFloat.pi / 6
cardlyView.animator.backgroundCardScale = 0.9
```

## 许可证

Cardly 采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。
