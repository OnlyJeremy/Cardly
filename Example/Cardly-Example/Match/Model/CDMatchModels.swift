import Foundation

// MARK: - Card Type

enum CDMatchCardType {
    case user
    case profileCompletion
    case promotion
}

// MARK: - User Card Model

struct CDMatchUserCard {
    let userID: Int
    let nickname: String
    let age: Int
    let distance: String
    let avatarURL: String
    let photos: [String]
    let bio: String
    let cardType: CDMatchCardType

    init(userID: Int, nickname: String, age: Int, distance: String, avatarURL: String, photos: [String] = [], bio: String = "", cardType: CDMatchCardType = .user) {
        self.userID = userID
        self.nickname = nickname
        self.age = age
        self.distance = distance
        self.avatarURL = avatarURL
        self.photos = photos
        self.bio = bio
        self.cardType = cardType
    }
}

// MARK: - JSON 解码用中间结构

private struct CDMatchCardJSON: Decodable {
    let userID: Int
    let nickname: String
    let age: Int
    let distance: String
    let avatarURL: String
    let photos: [String]
    let bio: String
}

// MARK: - Mock 数据（从 JSON 文件读取）

struct CDMatchMockData {

    /// 从 MRMatchMockCards.json 读取 100 条预生成的卡片数据
    /// - 数据固定不变，方便调试时按序号追踪卡片
    /// - 如果 JSON 读取失败，返回空数组并打印错误日志
    static func loadCards() -> [CDMatchUserCard] {
        guard let url = Bundle.main.url(forResource: "MRMatchMockCards", withExtension: "json") else {
            print("[CDMatchMockData] ❌ 找不到 MRMatchMockCards.json 文件")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let jsonCards = try JSONDecoder().decode([CDMatchCardJSON].self, from: data)
            let cards = jsonCards.map { json in
                CDMatchUserCard(
                    userID: json.userID,
                    nickname: json.nickname,
                    age: json.age,
                    distance: json.distance,
                    avatarURL: json.avatarURL,
                    photos: json.photos,
                    bio: json.bio
                )
            }
            print("[CDMatchMockData] ✅ 从 JSON 加载 \(cards.count) 条卡片数据")
            return cards
        } catch {
            print("[CDMatchMockData] ❌ JSON 解析失败: \(error)")
            return []
        }
    }
}
