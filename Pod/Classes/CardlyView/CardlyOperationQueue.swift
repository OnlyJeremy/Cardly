import Foundation

/// 卡片操作串行队列
/// 确保所有增删改操作按顺序执行，防止动画期间并发操作导致状态错乱
final class CardlyOperationQueue {

    /// 待执行的操作列表
    private var operations: [() -> Void] = []
    /// 是否有操作正在执行
    private(set) var isProcessing = false

    /// 队列是否为空
    var isEmpty: Bool { operations.isEmpty }

    /// 添加一个操作到队列末尾，如果当前没有操作在执行则立即执行
    func enqueue(_ operation: @escaping () -> Void) {
        operations.append(operation)
        processNext()
    }

    /// 标记当前操作已完成，自动执行队列中的下一个操作
    func markCompleted() {
        isProcessing = false
        processNext()
    }

    /// 清空队列中所有待执行的操作
    func clear() {
        operations.removeAll()
        isProcessing = false
    }

    /// 取出队列头部的操作并在主线程执行
    private func processNext() {
        guard !isProcessing, !operations.isEmpty else { return }
        isProcessing = true
        let op = operations.removeFirst()
        DispatchQueue.main.async {
            op()
        }
    }
}
