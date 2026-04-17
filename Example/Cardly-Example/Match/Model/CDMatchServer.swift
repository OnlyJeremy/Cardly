import Foundation

/// 模拟服务端分页接口
/// - 内部持有 100 条预生成的用户卡片池
/// - 每次请求返回 pageSize 条数据（默认 6），模拟真实网络分页
/// - 支持"定位变化"场景：重置游标，从头分页（模拟后端按新坐标重排推荐列表）
final class CDMatchServer {

    // MARK: - 单例

    static let shared = CDMatchServer()

    // MARK: - 配置

    /// 每页返回的卡片数量
    var pageSize: Int = 6

    // MARK: - 内部状态

    /// 完整的卡片池（模拟后端数据库）
    private var cardPool: [CDMatchUserCard] = []
    /// 当前分页游标（下一次请求从这里开始取）
    private var cursor: Int = 0

    // MARK: - 初始化

    private init() {
        resetPool()
    }

    // MARK: - 公开方法

    /// 请求下一页数据
    /// - Parameter completion: 返回本页卡片数组，空数组表示没有更多数据
    func fetchNextPage(completion: @escaping ([CDMatchUserCard]) -> Void) {
        // 模拟网络延迟 0.3~0.8 秒
        let delay = Double.random(in: 0.3...0.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            let page = self.nextPage()
            print("[CDMatchServer] 返回第 \(self.currentPage()) 页，\(page.count) 条数据，游标=\(self.cursor)/\(self.cardPool.count)")
            completion(page)
        }
    }

    /// 定位变化 — 重置游标，模拟后端按新坐标重新推荐
    /// - Parameter completion: 返回新位置的第一页数据
    func refreshForLocationChange(completion: @escaping ([CDMatchUserCard]) -> Void) {
        // 打乱卡片池顺序，模拟后端按新坐标重排
        cardPool.shuffle()
        cursor = 0
        print("[CDMatchServer] 定位变化，重新打乱推荐列表，游标重置为 0")
        fetchNextPage(completion: completion)
    }

    /// 全量重置 — 重新生成卡片池并重置游标
    /// - Parameter completion: 返回第一页数据
    func resetAndFetch(completion: @escaping ([CDMatchUserCard]) -> Void) {
        resetPool()
        print("[CDMatchServer] 全量重置，重新生成 \(cardPool.count) 条数据")
        fetchNextPage(completion: completion)
    }

    /// 当前是否还有更多数据
    var hasMore: Bool {
        cursor < cardPool.count
    }

    /// 剩余未发送的卡片数量
    var remainingCount: Int {
        max(0, cardPool.count - cursor)
    }

    // MARK: - 内部方法

    /// 取下一页数据，移动游标
    private func nextPage() -> [CDMatchUserCard] {
        guard cursor < cardPool.count else { return [] }
        let end = min(cursor + pageSize, cardPool.count)
        let page = Array(cardPool[cursor..<end])
        cursor = end
        return page
    }

    /// 当前页码（从 1 开始）
    private func currentPage() -> Int {
        return (cursor + pageSize - 1) / pageSize
    }

    /// 从 JSON 文件加载卡片池
    private func resetPool() {
        cardPool = CDMatchMockData.loadCards()
        cursor = 0
    }
}
