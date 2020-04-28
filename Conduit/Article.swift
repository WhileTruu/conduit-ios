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

    private static let decoder: JSONDecoder = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)

        return decoder
    }()

    static func fetchFeed() -> AnyPublisher<[Article], Error> {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "conduit.productionready.io"
        urlComponents.path = "/api/articles"
        urlComponents.queryItems = []

        guard let url = urlComponents.url else {
            preconditionFailure()
        }

        let urlRequest = URLRequest(url: url)

        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map {
                $0.data
            }
            .decode(type: Articles.self, decoder: decoder)
            .map {
                $0.articles
            }
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
