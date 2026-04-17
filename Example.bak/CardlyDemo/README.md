# Cardly Example Project

这是 Cardly Pod 的示例项目。

## 编译步骤

1. 在此目录运行：`pod install`
2. 打开 `Cardly-Example.xcworkspace`（不是 .xcodeproj）
3. 在 Xcode 中修复 Info.plist 的重复引用：
   - 选中 CardlyDemo target
   - Build Phases → Copy Bundle Resources
   - 删除 Info.plist
4. Build 项目

## 使用 Cardly

```swift
import Cardly

class MyViewController: UIViewController, CardlyViewDataSource, CardlyViewDelegate {
    @IBOutlet weak var cardlyView: CardlyView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardlyView.dataSource = self
        cardlyView.delegate = self
    }
    
    func numberOfCards(in cardlyView: CardlyView) -> Int { 10 }
    func cardlyView(_ cardlyView: CardlyView, viewForCardAt index: Int) -> UIView {
        UIView() // 自定义卡片视图
    }
    func cardlyView(_ cardlyView: CardlyView, overlayForCardAt index: Int) -> CardlyOverlayView? { nil }
    
    func cardlyView(_ cardlyView: CardlyView, didSwipeCardAt index: Int, in direction: CardlySwipeDirection) {
        print("Swiped: \(direction)")
    }
    func cardlyView(_ cardlyView: CardlyView, didShowCardAt index: Int) {}
}
```
