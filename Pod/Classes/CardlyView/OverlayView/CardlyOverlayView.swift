import UIKit

// MARK: - Overlay 基类（Pod 层提供，业务层继承）

/// 卡片拖拽叠层基类
/// 业务层继承此类，重写 update(progress:direction:) 实现自定义 LIKE/NOPE 效果
/// CardlyView 拖拽时自动调用，业务层无需在 delegate 回调中手动操作
class CardlyOverlayView: UIView {

    /// 拖拽进度更新 — CardlyView 拖拽过程中自动调用
    /// - Parameters:
    ///   - progress: 拖拽进度 0.0 ~ 1.0
    ///   - direction: 当前拖拽方向
    func update(progress: CGFloat, direction: CardlySwipeDirection) {
        // 子类重写，实现 LIKE/NOPE 叠层效果
    }

    /// 拖拽取消（回弹）时重置 — CardlyView 自动调用
    func reset() {
        // 子类重写，重置叠层状态
    }
}
