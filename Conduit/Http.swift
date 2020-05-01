import Combine
import Foundation
import Swift

enum Http {
    enum Error: Swift.Error {
        case SessionError(error: URLError)
        case BadBody
        case BadStatus(status: Int, data: Data)
        case InvalidResponse(response: URLResponse, data: Data)
        case Other(Swift.Error)

        static func fromGenericError(_ error: Swift.Error) -> Error {
            switch error {
            case is Swift.DecodingError:
                return .BadBody
            case let urlError as URLError:
                return .SessionError(error: urlError)
            case let httpError as Error:
                return httpError
            default:
                return .Other(error)
            }
        }
    }

    static func get<T: Decodable>(url: URL) -> AnyPublisher<T, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap(throwErrorOnBadStatus)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .mapError(Error.fromGenericError)
            .eraseToAnyPublisher()
    }

    static func post<T: Decodable>(url: URL, body: Data?) -> AnyPublisher<
        T, Error
    > {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(throwErrorOnBadStatus)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .mapError(Error.fromGenericError)
            .eraseToAnyPublisher()
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

    private static func throwErrorOnBadStatus(
        output: URLSession.DataTaskPublisher.Output
    ) throws -> URLSession.DataTaskPublisher.Output {
        guard let httpResponse = output.response as? HTTPURLResponse
        else {
            throw Http.Error.InvalidResponse(
                response: output.response, data: output.data)
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode <= 300
        else {
            throw Http.Error.BadStatus(
                status: httpResponse.statusCode, data: output.data)
        }

        return output
    }
}
