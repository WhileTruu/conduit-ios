import Foundation
import XCTest

@testable import Conduit

class ConduitTests: XCTestCase {
    func testUserDecoder() throws {
        let data =
            "{\"user\":{\"token\":\"token\",\"username\":\"buttdragon\",\"image\":null}}"
            .data(using: .utf8)

        let expected = User(token: "token", username: "buttdragon", image: nil)

        let result: User = try JSONDecoder().decode(User.self, from: data!)

        XCTAssertEqual(expected.username, result.username)
        XCTAssertEqual(expected.token, result.token)
        XCTAssertEqual(expected.image, result.image)
    }

    func testArticleDecoder() throws {
        let date: Date = {
            var dateComponents = DateComponents()
            dateComponents.year = 1980
            dateComponents.month = 7
            dateComponents.day = 11
            dateComponents.timeZone = TimeZone(abbreviation: "UTC")
            dateComponents.hour = 8
            dateComponents.minute = 34

            return Calendar.current.date(from: dateComponents)!
        }()

        let article = Article(
            slug: Article.Slug(string: "rocket-progress"),
            title: "Rocket progress",
            description: "Space must go faster",
            body:
                "Harasho progress, but 18 years to launch our first comrades is a long time. Technology must advance faster or there will be no kolkhoz on the red planet in our lifetime.",
            tagList: [],
            createdAt: date,
            updatedAt: date,
            favorited: true,
            favoritesCount: 69,
            author: Article.Author(
                username: "Leon Umsk",
                bio: "🐓 🐂 ☀️ 🚛 🧠 🦠",
                image: "",
                following: true
            )
        )

        let data = """
            {
                "title": "Rocket progress",
                "slug": "rocket-progress",
                "body": "Harasho progress, but 18 years to launch our first comrades is a long time. Technology must advance faster or there will be no kolkhoz on the red planet in our lifetime.",
                "createdAt": "1980-07-11T08:34:00.000Z",
                "updatedAt": "1980-07-11T08:34:00.000Z",
                "tagList": [],
                "description": "Space must go faster",
                "author": {
                    "username": "Leon Umsk",
                    "bio": "🐓 🐂 ☀️ 🚛 🧠 🦠",
                    "image": "",
                    "following": true 
                },
                "favorited": true,
                "favoritesCount": 69
            }
            """
            .data(using: .utf8)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Article.dateFormatter)

        let result: Article = try decoder.decode(
            Article.self,
            from: data!
        )

        XCTAssertEqual(article.title, result.title)
        XCTAssertEqual(article.createdAt, result.createdAt)
    }
}
