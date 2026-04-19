import UIKit

/// 背景卡片堆叠方向
public enum CardlyStackDirection {
    case top     // 背景卡片向上偏移（从顶部露出）
    case bottom  // 背景卡片向下偏移（从底部露出）
}

/// 卡片动画引擎，负责拖拽变换、滑出、回弹、缩放等所有动画效果
public final class CardlyAnimator {

    // MARK: - 动画配置参数

    /// 滑动触发阈值（0~1），拖拽超过此比例即判定为有效滑动
    public var swipeThreshold: CGFloat = 0.4
    /// 拖拽时最大旋转角度
    public var maxRotationAngle: CGFloat = .pi / 8
    /// 滑出动画时长
    public var swipeOutDuration: TimeInterval = 0.3
    /// 回弹动画时长
    public var snapBackDuration: TimeInterval = 0.25
    /// 下一张卡片放大动画时长
    public var nextCardScaleDuration: TimeInterval = 0.2
    /// 背景卡片缩放比例（1.0 表示无缩放，越小背景卡越小）
    public var backgroundCardScale: CGFloat = 0.95
    /// 背景卡片垂直偏移量（单位 pt，配合 stackDirection 决定偏移方向）
    public var backgroundCardVerticalOffset: CGFloat = 12
    /// 背景卡片堆叠方向（.bottom = 从底部露出，.top = 从顶部露出）
    public var stackDirection: CardlyStackDirection = .bottom

    // MARK: - 动画状态

    /// 是否正在执行动画，用于防止动画期间响应手势
    public private(set) var isAnimating = false

    // MARK: - 拖拽变换

    /// 根据手指拖拽的偏移量，对当前卡片应用平移+旋转变换
    public func applyDragTransform(to card: UIView, translation: CGPoint, containerWidth: CGFloat) {
        let progress = translation.x / containerWidth
        let rotation = progress * maxRotationAngle
        let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            .rotated(by: rotation)
        card.transform = transform
    }

    /// 根据拖拽偏移量计算滑动进度（0~1）和方向
    public func dragProgress(translation: CGPoint, containerWidth: CGFloat) -> (progress: CGFloat, direction: CardlySwipeDirection) {
        let progress = abs(translation.x) / containerWidth
        let direction: CardlySwipeDirection = translation.x > 0 ? .right : .left
        return (min(progress, 1.0), direction)
    }

    // MARK: - 背景卡片变换

    /// 根据拖拽进度，对背景卡片应用缩放+偏移变换（拖拽越远，背景卡越接近正常大小）
    public func applyBackgroundTransform(to card: UIView, progress: CGFloat) {
        let scale = backgroundCardScale + (1.0 - backgroundCardScale) * min(progress / swipeThreshold, 1.0)
        let offset = backgroundCardVerticalOffset * (1.0 - min(progress / swipeThreshold, 1.0))
        let directionMultiplier: CGFloat = stackDirection == .top ? -1 : 1
        card.transform = CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: 0, y: offset * directionMultiplier / scale)
    }

    /// 返回背景卡片的初始变换（缩小+偏移，方向由 stackDirection 决定）
    public func initialBackgroundTransform() -> CGAffineTransform {
        let directionMultiplier: CGFloat = stackDirection == .top ? -1 : 1
        return CGAffineTransform(scaleX: backgroundCardScale, y: backgroundCardScale)
            .translatedBy(x: 0, y: backgroundCardVerticalOffset * directionMultiplier / backgroundCardScale)
    }

    // MARK: - 滑出动画

    /// 卡片飞出屏幕动画（左滑/右滑），完成后回调
    public func animateSwipeOut(card: UIView, direction: CardlySwipeDirection, containerWidth: CGFloat, completion: @escaping () -> Void) {
        isAnimating = true
        let translationX: CGFloat = direction == .right ? containerWidth * 1.5 : -containerWidth * 1.5
        let rotation = direction == .right ? maxRotationAngle : -maxRotationAngle

        UIView.animate(withDuration: swipeOutDuration, delay: 0, options: .curveEaseIn) {
            card.transform = CGAffineTransform(translationX: translationX, y: 0).rotated(by: rotation)
            card.alpha = 0.5
        } completion: { [weak self] _ in
            self?.isAnimating = false
            completion()
        }
    }

    // MARK: - 回弹动画

    /// 未达到滑动阈值时，卡片弹回原位（弹簧效果），背景卡恢复初始变换
    public func animateSnapBack(card: UIView, backgroundCard: UIView?, completion: @escaping () -> Void) {
        isAnimating = true
        UIView.animate(withDuration: snapBackDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) {
            card.transform = .identity
        } completion: { [weak self] _ in
            self?.isAnimating = false
            completion()
        }

        if let bg = backgroundCard {
            UIView.animate(withDuration: snapBackDuration) {
                bg.transform = self.initialBackgroundTransform()
            }
        }
    }

    // MARK: - 下一张卡片放大

    /// 当前卡片移除后，下一张卡片从缩放状态恢复到正常大小
    public func animateNextCardScaleUp(_ card: UIView, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: nextCardScaleDuration, delay: 0, options: .curveEaseOut) {
            card.transform = .identity
        } completion: { _ in
            completion?()
        }
    }
}
