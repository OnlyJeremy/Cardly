import UIKit

/// 卡片堆叠容器视图
/// 单一数据源架构，所有增删改操作通过操作队列串行执行，确保动画期间状态安全
open class CardlyView: UIView {

    // MARK: - 公开属性

    /// 数据源
    public weak var dataSource: CardlyViewDataSource?
    /// 代理
    public weak var delegate: CardlyViewDelegate?

    /// 动画引擎（可配置动画参数）
    public let animator = CardlyAnimator()

    /// 同时可见的卡片数量，默认 2
    public var visibleCardCount: Int = 2

    /// 剩余多少张时触发预加载回调，默认 5
    public var prefetchThreshold: Int = 5

    /// 是否允许手势拖拽滑动，设为 false 时只能通过代码触发滑动
    public var isSwipeEnabled: Bool = true

    /// 当前展示的卡片在数据源中的索引
    public private(set) var currentCardIndex: Int = 0

    // MARK: - 私有属性

    /// 当前可见的卡片视图数组（最多 visibleCardCount 个）
    private var cardViews: [UIView] = []
    /// 当前可见卡片对应的 overlay 数组（与 cardViews 一一对应，nil 表示该卡片无叠层）
    private var overlayViews: [CardlyOverlayView?] = []
    /// 操作串行队列，保护动画期间的状态安全
    private let operationQueue = CardlyOperationQueue()
    /// 拖拽手势
    private var panGesture: UIPanGestureRecognizer!
    /// 点击手势
    private var tapGesture: UITapGestureRecognizer!
    /// 数据源中的卡片总数（内部维护，避免频繁查询数据源）
    private var totalCards: Int = 0
    /// 是否已触发预加载（防止重复触发）
    private var hasPendingPrefetch = false
    /// 数据重载代际计数器 — 每次 reloadData 递增，过期的动画 completion 检测到代际不匹配后直接跳过，避免污染新状态
    private var reloadGeneration: Int = 0

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGesture()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGesture()
    }

    // MARK: - 手势设置

    private func setupGesture() {
        // 拖拽手势 — 用于滑动卡片
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        // 点击手势 — 用于查看详情，需要拖拽手势失败后才触发
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.require(toFail: panGesture)
        addGestureRecognizer(tapGesture)
    }

    // MARK: - 公开 API

    /// 刷新数据，保持当前位置（类似 UITableView.reloadData）
    /// 适用场景：插入特殊卡、定位刷新、数据变化后刷新
    /// 安全保证：无论内部是否有动画或队列操作，都会立即清理干净后重建
    public func reloadData() {
        // 代际递增 — 让所有进行中的动画 completion 失效
        reloadGeneration += 1
        // 清除操作队列中排队等待的操作
        operationQueue.clear()
        // 取消所有子视图动画并移除（包括不在 cardViews 中的飞出动画残留）
        cancelAndRemoveAllSubviews()
        cardViews.removeAll()

        // 重新查询数据源数量
        totalCards = dataSource?.numberOfCards(in: self) ?? 0
        // 如果当前索引超出范围，调整到最后一张
        if currentCardIndex >= totalCards {
            currentCardIndex = max(totalCards - 1, 0)
        }

        // 重新布局可见卡片
        layoutVisibleCards()
        if currentCardIndex < totalCards {
            delegate?.cardlyView(self, didShowCardAt: currentCardIndex)
        } else {
            delegate?.cardlyViewDidRunOutOfCards(self)
        }
    }

    /// 重置到第一张并重新加载所有数据
    /// 适用场景：首次加载、切换账号、全量重置
    /// 安全保证：无论内部是否有动画或队列操作，都会立即清理干净后重建
    public func reloadDataAndResetIndex() {
        // 代际递增 — 让所有进行中的动画 completion 失效
        reloadGeneration += 1
        operationQueue.clear()
        cancelAndRemoveAllSubviews()
        cardViews.removeAll()
        currentCardIndex = 0
        hasPendingPrefetch = false
        totalCards = dataSource?.numberOfCards(in: self) ?? 0
        layoutVisibleCards()
        if totalCards > 0 {
            delegate?.cardlyView(self, didShowCardAt: currentCardIndex)
        } else {
            delegate?.cardlyViewDidRunOutOfCards(self)
        }
    }

    /// 代码触发滑动（非手势），带飞出动画
    /// 适用场景：点击 LIKE/NOPE 按钮
    public func swipeCurrentCard(direction: CardlySwipeDirection, completion: (() -> Void)? = nil) {
        enqueueOperation { [weak self] in
            self?.performSwipe(direction: direction, completion: completion)
        }
    }

    /// 返回指定数据索引对应的当前可见卡片视图
    public func viewForCard(at index: Int) -> UIView? {
        let visibleIndex = index - currentCardIndex
        guard visibleIndex >= 0, visibleIndex < cardViews.count else { return nil }
        return cardViews[visibleIndex]
    }

    /// 移除当前卡片（缩小淡出动画，不走滑动飞出）
    /// 适用场景：Super Hi、屏蔽用户
    public func removeCurrentCard(completion: (() -> Void)? = nil) {
        enqueueOperation { [weak self] in
            self?.performRemoveCurrentCard(completion: completion)
        }
    }

    /// 移除指定索引的卡片
    /// 适用场景：通话建立后删除已匹配用户的卡片
    public func removeCard(at index: Int, completion: (() -> Void)? = nil) {
        enqueueOperation { [weak self] in
            self?.performRemoveCard(at: index, completion: completion)
        }
    }

    /// 按条件批量移除卡片
    /// 适用场景：通话列表变化后批量删除已匹配用户的卡片
    public func removeCards(where predicate: @escaping (Int) -> Bool, completion: (() -> Void)? = nil) {
        enqueueOperation { [weak self] in
            self?.performRemoveCards(where: predicate, completion: completion)
        }
    }

    /// 在指定索引处插入一张卡片（数据源需先插入数据）
    /// 适用场景：插入特殊卡（完善资料卡、广告卡）
    public func insertCard(at index: Int, completion: (() -> Void)? = nil) {
        enqueueOperation { [weak self] in
            self?.performInsertCard(at: index, completion: completion)
        }
    }

    /// 刷新指定索引的卡片内容（不重建，原地替换视图）
    /// 适用场景：用户上传新头像后更新卡片显示
    public func reloadCard(at index: Int) {
        let visibleIndex = index - currentCardIndex
        guard visibleIndex >= 0, visibleIndex < cardViews.count else { return }
        guard let newView = dataSource?.cardlyView(self, viewForCardAt: index) else { return }
        let oldView = cardViews[visibleIndex]
        newView.frame = oldView.frame
        newView.transform = oldView.transform
        insertSubview(newView, belowSubview: oldView)
        oldView.removeFromSuperview()
        cardViews[visibleIndex] = newView
        // 重建 overlay
        let overlay = dataSource?.cardlyView(self, overlayForCardAt: index)
        if let overlay = overlay {
            overlay.frame = newView.bounds
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.alpha = 0
            newView.addSubview(overlay)
        }
        overlayViews[visibleIndex] = overlay
        if visibleIndex == 0 {
            addGestureToTop(newView)
        }
    }

    /// 业务层追加新卡片后调用，更新内部计数并补充可见卡片
    /// 适用场景：预加载请求返回新数据后调用
    public func appendCards(count: Int, completion: (() -> Void)? = nil) {
        enqueueOperation { [weak self] in
            self?.performAppendCards(count: count, completion: completion)
        }
    }

    // MARK: - 手势处理

    /// 点击手势处理 — 触发 didTapCardAt 回调
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !cardViews.isEmpty, !animator.isAnimating, !operationQueue.isProcessing else { return }
        delegate?.cardlyView(self, didTapCardAt: currentCardIndex)
    }

    /// 拖拽手势处理 — 实时更新卡片变换，松手时判断是否触发滑动
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isSwipeEnabled else { return }
        guard !cardViews.isEmpty else { return }
        guard !animator.isAnimating else { return }
        guard !operationQueue.isProcessing else { return }

        let topCard = cardViews[0]
        let translation = gesture.translation(in: self)
        let (progress, direction) = animator.dragProgress(translation: translation, containerWidth: bounds.width)

        switch gesture.state {
        case .changed:
            // 显示 overlay
            overlayViews.first??.alpha = 1
            // 实时更新当前卡片的拖拽变换
            animator.applyDragTransform(to: topCard, translation: translation, containerWidth: bounds.width)
            // 实时更新背景卡片的缩放
            if cardViews.count > 1 {
                animator.applyBackgroundTransform(to: cardViews[1], progress: progress)
            }
            // 自动更新叠层（LIKE/NOPE 效果）
            overlayViews.first??.update(progress: progress, direction: direction)
            // 通知代理拖拽进度（用于业务逻辑：震动反馈、埋点等）
            delegate?.cardlyView(self, draggingCardAt: currentCardIndex, progress: progress, direction: direction)

        case .ended, .cancelled:
            let velocity = gesture.velocity(in: self)
            // 判断是否触发滑动：拖拽距离超过阈值，或手指速度够快
            let shouldSwipe = progress > animator.swipeThreshold || abs(velocity.x) > 800

            if shouldSwipe {
                // 根据拖拽方向+速度方向确定最终滑动方向
                let swipeDirection: CardlySwipeDirection = (translation.x + velocity.x * 0.1) > 0 ? .right : .left
                guard delegate?.cardlyView(self, shouldSwipeCardAt: currentCardIndex, in: swipeDirection) ?? true else {
                    let gen = reloadGeneration
                    overlayViews.first??.reset()
                    animator.animateSnapBack(card: topCard, backgroundCard: cardViews.count > 1 ? cardViews[1] : nil) { [weak self] in
                        guard let self, gen == self.reloadGeneration else { return }
                        self.overlayViews.first??.alpha = 0
                        self.delegate?.cardlyView(self, didCancelSwipeAt: self.currentCardIndex)
                    }
                    return
                }
                completeSwipe(direction: swipeDirection)
            } else {
                // 未达阈值，回弹到原位
                let gen = reloadGeneration
                overlayViews.first??.reset()
                animator.animateSnapBack(card: topCard, backgroundCard: cardViews.count > 1 ? cardViews[1] : nil) { [weak self] in
                    guard let self, gen == self.reloadGeneration else { return }
                    self.overlayViews.first??.alpha = 0
                    self.delegate?.cardlyView(self, didCancelSwipeAt: self.currentCardIndex)
                }
            }

        default:
            break
        }
    }

    // MARK: - 滑动完成处理

    /// 手势滑动完成后的动画和状态更新（不经过操作队列，因为是手势直接触发）
    private func completeSwipe(direction: CardlySwipeDirection) {
        guard !cardViews.isEmpty else { return }
        let topCard = cardViews[0]
        let swipedIndex = currentCardIndex
        let gen = reloadGeneration

        // 当前卡片飞出动画
        animator.animateSwipeOut(card: topCard, direction: direction, containerWidth: bounds.width) { [weak self] in
            guard let self, gen == self.reloadGeneration else { return }
            topCard.removeFromSuperview()
            self.cardViews.removeFirst()
            self.overlayViews.removeFirst()
            self.currentCardIndex += 1

            self.delegate?.cardlyView(self, didSwipeCardAt: swipedIndex, in: direction)
            self.afterCardRemoved()
        }

        // 下一张卡片同步放大
        if cardViews.count > 1 {
            animator.animateNextCardScaleUp(cardViews[1])
        }
    }

    // MARK: - 操作队列具体实现

    /// 代码触发滑动的具体实现
    private func performSwipe(direction: CardlySwipeDirection, completion: (() -> Void)? = nil) {
        guard !cardViews.isEmpty else {
            operationQueue.markCompleted()
            completion?()
            return
        }
        guard delegate?.cardlyView(self, shouldSwipeCardAt: currentCardIndex, in: direction) ?? true else {
            operationQueue.markCompleted()
            completion?()
            return
        }
        let topCard = cardViews[0]
        let swipedIndex = currentCardIndex
        let gen = reloadGeneration

        animator.animateSwipeOut(card: topCard, direction: direction, containerWidth: bounds.width) { [weak self] in
            guard let self, gen == self.reloadGeneration else { return }
            topCard.removeFromSuperview()
            self.cardViews.removeFirst()
            self.overlayViews.removeFirst()
            self.currentCardIndex += 1

            self.delegate?.cardlyView(self, didSwipeCardAt: swipedIndex, in: direction)
            self.afterCardRemoved()
            self.operationQueue.markCompleted()
            completion?()
        }

        if cardViews.count > 1 {
            animator.animateNextCardScaleUp(cardViews[1])
        }
    }

    /// 移除当前卡片的具体实现（缩小+淡出动画）
    private func performRemoveCurrentCard(completion: (() -> Void)? = nil) {
        guard !cardViews.isEmpty else {
            operationQueue.markCompleted()
            completion?()
            return
        }
        let topCard = cardViews[0]
        let removedIndex = currentCardIndex
        let gen = reloadGeneration

        UIView.animate(withDuration: 0.2, animations: {
            topCard.alpha = 0
            topCard.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { [weak self] _ in
            guard let self, gen == self.reloadGeneration else { return }
            topCard.removeFromSuperview()
            self.cardViews.removeFirst()
            self.overlayViews.removeFirst()
            self.currentCardIndex += 1

            self.delegate?.cardlyView(self, didRemoveCardAt: removedIndex)
            self.afterCardRemoved()
            self.operationQueue.markCompleted()
            completion?()
        }

        if cardViews.count > 1 {
            animator.animateNextCardScaleUp(cardViews[1])
        }
    }

    /// 移除指定索引卡片的具体实现
    private func performRemoveCard(at index: Int, completion: (() -> Void)? = nil) {
        let visibleIndex = index - currentCardIndex

        if visibleIndex == 0 {
            // 移除的是当前卡片，走当前卡片移除逻辑
            performRemoveCurrentCard(completion: completion)
            return
        }

        if visibleIndex > 0, visibleIndex < cardViews.count {
            // 移除的是可见范围内的非当前卡片
            let card = cardViews[visibleIndex]
            card.removeFromSuperview()
            cardViews.remove(at: visibleIndex)
            overlayViews.remove(at: visibleIndex)
        }

        // 调用方需在调用前先从数据源中删除对应数据
        totalCards -= 1
        delegate?.cardlyView(self, didRemoveCardAt: index)

        // 尝试在可见区域末尾补充新卡片
        loadNextCardAtEnd()
        operationQueue.markCompleted()
        completion?()
    }

    /// 按条件批量移除卡片的具体实现
    private func performRemoveCards(where predicate: (Int) -> Bool, completion: (() -> Void)? = nil) {
        // 收集所有需要移除的索引
        var indicesToRemove: [Int] = []
        for i in currentCardIndex..<totalCards {
            if predicate(i) {
                indicesToRemove.append(i)
            }
        }

        guard !indicesToRemove.isEmpty else {
            operationQueue.markCompleted()
            completion?()
            return
        }

        let removingCurrent = indicesToRemove.contains(currentCardIndex)

        // 从后往前移除可见卡片视图，避免索引错乱
        for dataIndex in indicesToRemove.sorted(by: >) {
            let visibleIndex = dataIndex - currentCardIndex
            if visibleIndex >= 0, visibleIndex < cardViews.count {
                cardViews[visibleIndex].removeFromSuperview()
                cardViews.remove(at: visibleIndex)
                overlayViews.remove(at: visibleIndex)
            }
        }

        // 调整内部计数
        let removedBeforeCurrent = indicesToRemove.filter { $0 < currentCardIndex }.count
        totalCards -= indicesToRemove.count
        currentCardIndex -= removedBeforeCurrent

        if removingCurrent {
            // 当前卡被移除，需要重建可见卡片
            rebuildVisibleCards()
            if currentCardIndex < totalCards {
                delegate?.cardlyView(self, didShowCardAt: currentCardIndex)
            } else {
                delegate?.cardlyViewDidRunOutOfCards(self)
            }
        } else {
            // 当前卡未被移除，补充可见区域
            while cardViews.count < visibleCardCount, currentCardIndex + cardViews.count < totalCards {
                loadNextCardAtEnd()
            }
        }

        // 逐个通知代理
        for idx in indicesToRemove {
            delegate?.cardlyView(self, didRemoveCardAt: idx)
        }
        operationQueue.markCompleted()
        completion?()
    }

    /// 插入卡片的具体实现
    private func performInsertCard(at index: Int, completion: (() -> Void)? = nil) {
        totalCards += 1

        let visibleIndex = index - currentCardIndex
        if visibleIndex >= 0, visibleIndex < visibleCardCount {
            // 插入位置在可见范围内，需要重建可见卡片
            rebuildVisibleCards()
        }
        operationQueue.markCompleted()
        completion?()
    }

    /// 追加卡片的具体实现
    private func performAppendCards(count: Int, completion: (() -> Void)? = nil) {
        totalCards += count
        hasPendingPrefetch = false
        while cardViews.count < visibleCardCount, currentCardIndex + cardViews.count < totalCards {
            loadNextCardAtEnd()
        }
        operationQueue.markCompleted()
        completion?()
    }

    // MARK: - 卡片布局

    /// 根据当前索引和可见数量，创建并布局可见卡片
    private func layoutVisibleCards() {
        let count = min(visibleCardCount, totalCards - currentCardIndex)
        for i in 0..<count {
            let dataIndex = currentCardIndex + i
            guard let cardView = dataSource?.cardlyView(self, viewForCardAt: dataIndex) else { continue }
            configureCard(cardView, at: i, dataIndex: dataIndex)
            cardViews.append(cardView)
        }
    }

    /// 配置单张卡片的 frame、层级、变换，并叠加 overlay
    private func configureCard(_ card: UIView, at visibleIndex: Int, dataIndex: Int) {
        card.frame = bounds
        insertSubview(card, at: max(0, subviews.count - visibleIndex))

        if visibleIndex == 0 {
            // 顶部卡片：正常大小，允许交互
            card.transform = .identity
            addGestureToTop(card)
        } else {
            // 背景卡片：缩小+下移，禁止交互
            card.transform = animator.initialBackgroundTransform()
            card.isUserInteractionEnabled = false
        }

        // 叠加 overlay（由 dataSource 提供，nil 表示该卡片不需要叠层）
        let overlay = dataSource?.cardlyView(self, overlayForCardAt: dataIndex)
        if let overlay = overlay {
            overlay.frame = card.bounds
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.alpha = 0
            card.addSubview(overlay)
        }
        overlayViews.append(overlay)
    }

    /// 启用顶部卡片的用户交互
    private func addGestureToTop(_ card: UIView) {
        card.isUserInteractionEnabled = true
    }

    // MARK: - 卡片管理

    /// 卡片移除后的统一处理：放大下一张、补充末尾、触发回调、检查预加载
    private func afterCardRemoved() {
        // 新的顶部卡片放大到正常大小
        if let newTop = cardViews.first {
            newTop.isUserInteractionEnabled = true
            animator.animateNextCardScaleUp(newTop)
        }

        // 在可见区域末尾补充新卡片
        loadNextCardAtEnd()

        if currentCardIndex < totalCards {
            delegate?.cardlyView(self, didShowCardAt: currentCardIndex)
            checkPrefetch()
        } else {
            delegate?.cardlyViewDidRunOutOfCards(self)
        }
    }

    /// 检查是否需要触发预加载
    private func checkPrefetch() {
        let remaining = totalCards - currentCardIndex
        if remaining <= prefetchThreshold, !hasPendingPrefetch {
            hasPendingPrefetch = true
            delegate?.cardlyView(self, needsPrefetchWithRemainingCount: remaining)
        }
    }

    /// 在可见区域末尾加载下一张卡片
    private func loadNextCardAtEnd() {
        let nextDataIndex = currentCardIndex + cardViews.count
        guard nextDataIndex < totalCards else { return }
        guard cardViews.count < visibleCardCount else { return }
        guard let cardView = dataSource?.cardlyView(self, viewForCardAt: nextDataIndex) else { return }
        configureCard(cardView, at: cardViews.count, dataIndex: nextDataIndex)
        cardViews.append(cardView)
    }

    /// 重建所有可见卡片（移除旧视图后重新布局）
    private func rebuildVisibleCards() {
        for card in cardViews {
            card.removeFromSuperview()
        }
        cardViews.removeAll()
        overlayViews.removeAll()
        layoutVisibleCards()
    }

    /// 取消所有子视图的动画并移除（包括不在 cardViews 数组中的飞出动画残留视图）
    private func cancelAndRemoveAllSubviews() {
        for sub in subviews {
            sub.layer.removeAllAnimations()
            sub.removeFromSuperview()
        }
        overlayViews.removeAll()
    }

    // MARK: - 辅助方法

    /// 将操作加入队列（动画中或队列忙时排队，否则立即执行）
    private func enqueueOperation(_ operation: @escaping () -> Void) {
        operationQueue.enqueue(operation)
    }

    /// bounds 变化时更新卡片尺寸
    override public func layoutSubviews() {
        super.layoutSubviews()
        for (i, card) in cardViews.enumerated() {
            if card.transform == .identity || i > 0 {
                card.bounds = CGRect(origin: .zero, size: bounds.size)
                card.center = CGPoint(x: bounds.midX, y: bounds.midY)
            }
        }
    }
}
