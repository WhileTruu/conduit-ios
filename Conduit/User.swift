import Foundation

struct User: Decodable {
    let token: String
    let username: String
    let image: String?

    enum CodingKeys: CodingKey {
        case user
        case token
        case username
        case image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let user = try container.nestedContainer(
            keyedBy: CodingKeys.self, forKey: .user)
        token = try user.decode(String.self, forKey: .token)
        username = try user.decode(String.self, forKey: .username)
        image = try user.decodeIfPresent(String.self, forKey: .image)
    }
}
