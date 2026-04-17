import UIKit

// MARK: - 滑动方向

enum CardlySwipeDirection {
    case left   // 左滑（不喜欢）
    case right  // 右滑（喜欢）
}

// MARK: - 数据源协议

protocol CardlyViewDataSource: AnyObject {
    /// 返回卡片总数
    func numberOfCards(in cardlyView: CardlyView) -> Int
    /// 返回指定索引的卡片视图（业务层自定义 UI）
    func cardlyView(_ cardlyView: CardlyView, viewForCardAt index: Int) -> UIView
    /// 返回指定索引的拖拽叠层视图（可选，返回 nil 表示无叠层）
    /// CardlyView 会自动将叠层叠加在卡片上，并在拖拽时自动调用 update/reset
    func cardlyView(_ cardlyView: CardlyView, overlayForCardAt index: Int) -> CardlyOverlayView?
}

// MARK: - 数据源默认实现（可选方法）

extension CardlyViewDataSource {
    func cardlyView(_ cardlyView: CardlyView, overlayForCardAt index: Int) -> CardlyOverlayView? { nil }
}

// MARK: - 代理协议

protocol CardlyViewDelegate: AnyObject {
    /// 卡片被滑走时触发（手势滑动或代码调用 swipeCurrentCard）
    func cardlyView(_ cardlyView: CardlyView, didSwipeCardAt index: Int, in direction: CardlySwipeDirection)
    /// 新的卡片展示时触发（用于曝光上报）
    func cardlyView(_ cardlyView: CardlyView, didShowCardAt index: Int)
    /// 卡片被移除时触发（removeCurrentCard / removeCard / removeCards）
    func cardlyView(_ cardlyView: CardlyView, didRemoveCardAt index: Int)
    /// 所有卡片用完时触发（用于展示空状态）
    func cardlyViewDidRunOutOfCards(_ cardlyView: CardlyView)
    /// 拖拽过程中持续触发（用于业务逻辑如震动反馈、埋点，不用于操作叠层 UI）
    func cardlyView(_ cardlyView: CardlyView, draggingCardAt index: Int, progress: CGFloat, direction: CardlySwipeDirection)
    /// 拖拽取消（未达阈值回弹）时触发
    func cardlyView(_ cardlyView: CardlyView, didCancelSwipeAt index: Int)
    /// 点击卡片时触发（用于查看用户详情）
    func cardlyView(_ cardlyView: CardlyView, didTapCardAt index: Int)
    /// 剩余卡片数 <= prefetchThreshold 时触发（用于预加载下一页数据）
    func cardlyView(_ cardlyView: CardlyView, needsPrefetchWithRemainingCount remaining: Int)
}

// MARK: - 代理默认实现（可选方法）

extension CardlyViewDelegate {
    func cardlyView(_ cardlyView: CardlyView, didRemoveCardAt index: Int) {}
    func cardlyView(_ cardlyView: CardlyView, draggingCardAt index: Int, progress: CGFloat, direction: CardlySwipeDirection) {}
    func cardlyView(_ cardlyView: CardlyView, didCancelSwipeAt index: Int) {}
    func cardlyView(_ cardlyView: CardlyView, didTapCardAt index: Int) {}
    func cardlyView(_ cardlyView: CardlyView, needsPrefetchWithRemainingCount remaining: Int) {}
}
