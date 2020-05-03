import Combine
import Foundation

struct User {
    let token: String
    let username: String
    let image: String?
}

extension User: Codable {
    enum CodingKeys: CodingKey {
        case user
        case token
        case username
        case image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let user = try container.nestedContainer(
            keyedBy: CodingKeys.self,
            forKey: .user
        )
        token = try user.decode(String.self, forKey: .token)
        username = try user.decode(String.self, forKey: .username)
        image = try user.decodeIfPresent(String.self, forKey: .image)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var user = container.nestedContainer(
            keyedBy: CodingKeys.self,
            forKey: .user
        )
        try user.encode(token, forKey: .token)
        try user.encode(username, forKey: .username)
        try user.encode(image, forKey: .image)
    }
}
