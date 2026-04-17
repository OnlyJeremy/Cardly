import UIKit
import SnapKit
import Cardly

final class CDMatchViewController: UIViewController {

    // MARK: - 数据

    private var cards: [CDMatchUserCard] = []
    private let server = CDMatchServer.shared
    /// 是否已触发拖拽震动（防止重复震动）
    private var hasTriggeredHaptic = false
    /// 当前卡片开始展示的时间戳（用于计算曝光时长）
    private var cardExposureStartTime: CFAbsoluteTime = 0

    // MARK: - UI 组件

    private let deckView = CardlyView()

    /// 不喜欢按钮
    private let nopeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("不喜欢", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hex: 0xEF4444)
        btn.layer.cornerRadius = 30
        return btn
    }()

    /// Super Hi 按钮
    private let superHiButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Super", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize:12)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hex: 0x6366F1)
        btn.layer.cornerRadius = 26
        return btn
    }()

    /// 喜欢按钮
    private let likeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("喜欢", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize:14)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hex: 0x4ADE80)
        btn.layer.cornerRadius = 30
        return btn
    }()

    /// 空状态提示
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "没有更多卡片了"
        label.font = .systemFont(ofSize:18)
        label.textColor = UIColor(hex: 0x9CA3AF)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    /// 顶部状态栏（调试用，显示当前卡片信息）
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize:12)
        label.textColor = UIColor(hex: 0x6B7280)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // MARK: - 调试面板

    private let debugRow1: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        return stack
    }()

    private let debugRow2: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        return stack
    }()

    private let debugContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupDebugPanel()
        loadMockData()
    }

    // MARK: - UI 初始化

    private func setupUI() {
        // 卡片容器
        deckView.dataSource = self
        deckView.delegate = self
        deckView.visibleCardCount = 2
        deckView.prefetchThreshold = 5

        view.addSubview(statusLabel)
        view.addSubview(deckView)
        view.addSubview(nopeButton)
        view.addSubview(superHiButton)
        view.addSubview(likeButton)
        view.addSubview(emptyLabel)

        // 操作按钮事件
        nopeButton.addTarget(self, action: #selector(nopeTapped), for: .touchUpInside)
        superHiButton.addTarget(self, action: #selector(superHiTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        // SnapKit 约束
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        deckView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(nopeButton.snp.top).offset(-12)
        }

        superHiButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-100)
            make.size.equalTo(CGSize(width: 52, height: 52))
        }

        nopeButton.snp.makeConstraints { make in
            make.trailing.equalTo(superHiButton.snp.leading).offset(-24)
            make.centerY.equalTo(superHiButton)
            make.size.equalTo(CGSize(width: 60, height: 60))
        }

        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(superHiButton.snp.trailing).offset(24)
            make.centerY.equalTo(superHiButton)
            make.size.equalTo(CGSize(width: 60, height: 60))
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupDebugPanel() {
        debugContainer.addArrangedSubview(debugRow1)
        debugContainer.addArrangedSubview(debugRow2)
        view.addSubview(debugContainer)

        debugContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
        }

        // 第一行：核心操作
        let row1Actions: [(String, UIColor, Selector)] = [
            ("Super Hi", UIColor(hex: 0x8B5CF6), #selector(debugSuperHi)),
            ("删匹配卡", UIColor(hex: 0xF59E0B), #selector(debugDeleteMatched)),
            ("批量删除", UIColor(hex: 0xEF4444), #selector(debugBatchRemove)),
            ("插入特殊卡", UIColor(hex: 0x3B82F6), #selector(debugInsertSpecial)),
        ]

        // 第二行：数据操作
        let row2Actions: [(String, UIColor, Selector)] = [
            ("更新头像", UIColor(hex: 0x14B8A6), #selector(debugUpdateAvatar)),
            ("定位刷新", UIColor(hex: 0xEC4899), #selector(debugLocationRefresh)),
            ("追加数据", UIColor(hex: 0x06B6D4), #selector(debugAppendData)),
            ("全量重载", UIColor(hex: 0x6B7280), #selector(debugReloadAll)),
        ]

        for (title, color, sel) in row1Actions {
            debugRow1.addArrangedSubview(makeDebugButton(title: title, color: color, action: sel))
        }
        for (title, color, sel) in row2Actions {
            debugRow2.addArrangedSubview(makeDebugButton(title: title, color: color, action: sel))
        }
    }

    private func makeDebugButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize:11)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 8
        btn.snp.makeConstraints { make in
            make.height.equalTo(32)
        }
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    // MARK: - 数据加载

    /// 首次加载：从 Server 请求第一页数据
    private func loadMockData() {
        server.resetAndFetch { [weak self] page in
            guard let self = self else { return }
            self.cards = page
            self.deckView.reloadDataAndResetIndex()
            self.emptyLabel.isHidden = !page.isEmpty
            self.updateStatus()
            print("[划卡][首次加载] 获取 \(page.count) 张卡片，服务端剩余 \(self.server.remainingCount) 张")
        }
    }

    private func updateStatus() {
        let current = deckView.currentCardIndex
        let total = cards.count
        let remaining = total - current
        let currentName = current < total ? cards[current].nickname : "无"
        statusLabel.text = "[\(currentName)] 索引=\(current) | 总数=\(total) | 剩余=\(remaining)"
    }

    // MARK: - 操作按钮事件

    @objc private func likeTapped() {
        deckView.swipeCurrentCard(direction: .right)
    }

    @objc private func nopeTapped() {
        deckView.swipeCurrentCard(direction: .left)
    }

    @objc private func superHiTapped() {
        debugSuperHi()
    }

    // MARK: - 调试：Super Hi（移除当前卡片）

    @objc private func debugSuperHi() {
        let idx = deckView.currentCardIndex
        guard idx < cards.count else { return }
        let card = cards[idx]
        print("[划卡][Super Hi] 超级喜欢 → \(card.nickname) (userID=\(card.userID))")
        deckView.removeCurrentCard()
    }

    // MARK: - 调试：删匹配卡（模拟通话建立后删除）

    @objc private func debugDeleteMatched() {
        let currentIdx = deckView.currentCardIndex
        let candidates = (currentIdx + 1)..<cards.count
        guard !candidates.isEmpty else {
            print("[划卡][删匹配卡] 当前卡片后面没有可删除的卡片")
            return
        }
        let targetIdx = Int.random(in: candidates)
        let targetCard = cards[targetIdx]
        print("[划卡][删匹配卡] 删除已匹配用户: \(targetCard.nickname) (userID=\(targetCard.userID), 索引=\(targetIdx))")

        cards.remove(at: targetIdx)
        deckView.removeCard(at: targetIdx)
    }

    // MARK: - 调试：批量删除（模拟多个用户建立通话）

    @objc private func debugBatchRemove() {
        let currentIdx = deckView.currentCardIndex
        var indicesToRemove: [Int] = []

        // 模拟：删除当前卡片后面每隔 3 张的用户卡
        for i in (currentIdx + 1)..<cards.count {
            if (i - currentIdx) % 3 == 0, cards[i].cardType == .user {
                indicesToRemove.append(i)
            }
        }

        guard !indicesToRemove.isEmpty else {
            print("[划卡][批量删除] 没有符合条件的卡片可删除")
            return
        }

        let names = indicesToRemove.map { cards[$0].nickname }
        print("[划卡][批量删除] 删除 \(indicesToRemove.count) 张卡片: \(names)")

        // 从后往前删除数据源（避免索引错乱）
        for i in indicesToRemove.sorted(by: >) {
            cards.remove(at: i)
        }

        // 通知组件移除
        let removeSet = Set(indicesToRemove)
        deckView.removeCards { removeSet.contains($0) }
    }

    // MARK: - 调试：插入特殊卡（在当前卡后第 6 位插入完善资料卡）

    @objc private func debugInsertSpecial() {
        let insertIdx = min(deckView.currentCardIndex + 6, cards.count)
        let specialCard = CDMatchUserCard(
            userID: -Int.random(in: 100...999),
            nickname: "",
            age: 0,
            distance: "",
            avatarURL: "",
            cardType: .profileCompletion
        )
        print("[划卡][插入特殊卡] 在索引 \(insertIdx) 处插入完善资料卡")
        cards.insert(specialCard, at: insertIdx)
        deckView.insertCard(at: insertIdx)
    }

    // MARK: - 调试：更新头像（模拟头像更换后保留当前+3张，请求新数据追加）

    @objc private func debugUpdateAvatar() {
        let currentIdx = deckView.currentCardIndex
        guard currentIdx < cards.count else {
            print("[划卡][更新头像] 没有当前卡片")
            return
        }

        // 保留当前卡 + 后面3张，截掉其余的（3张是给网络请求留缓冲）
        let keepCount = currentIdx + 4
        let keptNames = cards[currentIdx..<min(keepCount, cards.count)].map { $0.nickname }
        cards = Array(cards.prefix(keepCount))
        print("[划卡][更新头像] 保留 \(keptNames)，向服务端请求新推荐数据...")

        // 请求新数据追加到后面
        server.fetchNextPage { [weak self] page in
            guard let self = self, !page.isEmpty else {
                print("[划卡][更新头像] 服务端无新数据")
                return
            }
            self.cards.append(contentsOf: page)
            self.deckView.reloadData()
            self.updateStatus()
            print("[划卡][更新头像] 完成，追加 \(page.count) 张新卡片，服务端剩余 \(self.server.remainingCount) 张")
        }
    }

    // MARK: - 调试：定位刷新（保留当前卡，替换后续所有卡片）

    @objc private func debugLocationRefresh() {
        let currentIdx = deckView.currentCardIndex
        guard currentIdx < cards.count else {
            print("[划卡][定位刷新] 没有当前卡片")
            return
        }

        let currentCard = cards[currentIdx]
        print("[划卡][定位刷新] 保留当前卡 \(currentCard.nickname)，向服务端请求新位置数据...")

        server.refreshForLocationChange { [weak self] page in
            guard let self = self else { return }
            // 截断当前卡后面的数据，追加服务端新数据，保持 currentIndex 不变
            self.cards = Array(self.cards.prefix(currentIdx + 1)) + page
            self.deckView.reloadData()
            self.updateStatus()
            print("[划卡][定位刷新] 完成，当前卡=\(currentCard.nickname)，索引=\(currentIdx)，新增 \(page.count) 张，服务端剩余 \(self.server.remainingCount) 张")
        }
    }

    // MARK: - 调试：追加数据（模拟预加载请求返回）

    @objc private func debugAppendData() {
        guard server.hasMore else {
            print("[划卡][追加数据] 服务端已无更多数据")
            return
        }

        server.fetchNextPage { [weak self] page in
            guard let self = self, !page.isEmpty else {
                print("[划卡][追加数据] 返回空数据")
                return
            }
            print("[划卡][追加数据] 追加 \(page.count) 张新卡片，服务端剩余 \(self.server.remainingCount) 张")
            self.cards.append(contentsOf: page)
            self.deckView.appendCards(count: page.count)
            self.updateStatus()
        }
    }

    // MARK: - 调试：全量重载（重置所有数据从头开始）

    @objc private func debugReloadAll() {
        print("[划卡][全量重载] 重新生成卡片池，从第一页开始")
        loadMockData()
    }
}

// MARK: - CardlyViewDataSource 数据源

extension CDMatchViewController: CardlyViewDataSource {

    func numberOfCards(in cardlyView: CardlyView) -> Int {
        cards.count
    }

    func cardlyView(_ cardlyView: CardlyView, viewForCardAt index: Int) -> UIView {
        let card = cards[index]
        switch card.cardType {
        case .user:
            let cardView = CDMatchCardView()
            cardView.configure(with: card)
            return cardView
        case .profileCompletion:
            return CDMatchSpecialCardView()
        case .promotion:
            let cardView = CDMatchCardView()
            cardView.configure(with: card)
            return cardView
        }
    }

    func cardlyView(_ cardlyView: CardlyView, overlayForCardAt index: Int) -> CardlyOverlayView? {
        let card = cards[index]
        // 用户卡片需要 LIKE/NOPE 叠层，特殊卡片不需要
        return card.cardType == .user ? CDMatchOverlayView() : nil
    }
}

// MARK: - CardlyViewDelegate 代理

extension CDMatchViewController: CardlyViewDelegate {

    func cardlyView(_ cardlyView: CardlyView, didSwipeCardAt index: Int, in direction: CardlySwipeDirection) {
        let card = cards[index]
        let duration = Int((CFAbsoluteTimeGetCurrent() - cardExposureStartTime) * 1000)
        let directionText = direction == .right ? "右滑(喜欢)" : "左滑(不喜欢)"
        print("[划卡][滑动] \(directionText) → \(card.nickname) (userID=\(card.userID), 曝光时长=\(duration)ms)")
        hasTriggeredHaptic = false
        updateStatus()
    }

    func cardlyView(_ cardlyView: CardlyView, didShowCardAt index: Int) {
        guard index < cards.count else { return }
        let card = cards[index]
        cardExposureStartTime = CFAbsoluteTimeGetCurrent()
        print("[划卡][展示] 当前展示 → \(card.nickname) (userID=\(card.userID), 索引=\(index), 类型=\(card.cardType))")
        emptyLabel.isHidden = true
        updateStatus()
    }

    func cardlyView(_ cardlyView: CardlyView, didRemoveCardAt index: Int) {
        print("[划卡][移除] 移除卡片，索引=\(index)")
        hasTriggeredHaptic = false
        updateStatus()
    }

    func cardlyViewDidRunOutOfCards(_ cardlyView: CardlyView) {
        print("[划卡][空状态] 所有卡片已用完")
        emptyLabel.isHidden = false
        updateStatus()
    }

    func cardlyView(_ cardlyView: CardlyView, draggingCardAt index: Int, progress: CGFloat, direction: CardlySwipeDirection) {
        // 叠层（LIKE/NOPE）由 CardlyView 自动处理，这里只做业务逻辑
        // 拖拽进度达到 20% 时触发震动反馈
        if progress >= 0.2, !hasTriggeredHaptic {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            hasTriggeredHaptic = true
        }
    }

    func cardlyView(_ cardlyView: CardlyView, didCancelSwipeAt index: Int) {
        // 叠层重置由 CardlyView 自动处理，这里只重置震动标记
        hasTriggeredHaptic = false
    }

    func cardlyView(_ cardlyView: CardlyView, didTapCardAt index: Int) {
        guard index < cards.count else { return }
        let card = cards[index]
        print("[划卡][点击] 点击查看详情 → \(card.nickname) (userID=\(card.userID))")
        // TODO: 跳转到用户详情页
    }

    func cardlyView(_ cardlyView: CardlyView, needsPrefetchWithRemainingCount remaining: Int) {
        print("[划卡][预加载] 剩余 \(remaining) 张卡片，触发预加载请求，服务端剩余 \(server.remainingCount) 张")
        debugAppendData()
    }
}
