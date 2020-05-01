import Combine
import Foundation

struct Article: Decodable {
    struct Author: Decodable {
        let username: String
        let bio: String?
        let image: String
        let following: Bool
    }

    let slug: Slug
    let title: String
    let description: String
    let body: String
    let tagList: [String]
    let createdAt: Date
    let updatedAt: Date
    let favorited: Bool
    let favoritesCount: Int
    let author: Author
}

extension Article {
    private struct Articles: Decodable {
        let articles: [Article]
    }

    static func fetchFeed() -> AnyPublisher<[Article], Http.Error> {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "conduit.productionready.io"
        urlComponents.path = "/api/articles"
        urlComponents.queryItems = []

        guard let url = urlComponents.url else { preconditionFailure() }

        return (Http.get(url: url) as AnyPublisher<Articles, Http.Error>)
            .map(\.articles)
            .eraseToAnyPublisher()

    }
}

extension Article: Identifiable {
    var id: Article.Slug {
        slug
    }
}

// MARK: Article.Slug

extension Article {
    struct Slug: Hashable {
        let string: String
    }
}

extension Article.Slug: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        string = value
    }
}

extension Article.Slug: CustomStringConvertible {
    var description: String {
        string
    }
}

extension Article.Slug: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        string = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
}
