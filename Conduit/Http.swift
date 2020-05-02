import Combine
import Foundation
import Swift

enum Http {
    enum Error: Swift.Error {
        case SessionError(error: URLError)
        case BadBody(decodingError: Swift.DecodingError)
        case BadStatus(status: Int, data: Data)
        case InvalidResponse(response: URLResponse, data: Data)
        case Other(Swift.Error)

        static func fromGenericError(_ error: Swift.Error) -> Error {
            switch error {
            case let decodingError as Swift.DecodingError:
                return .BadBody(decodingError: decodingError)
            case let urlError as URLError:
                return .SessionError(error: urlError)
            case let httpError as Error:
                return httpError
            default:
                return .Other(error)
            }
        }
    }

    static func get<T: Decodable>(url: URL, decoder: JSONDecoder)
        -> AnyPublisher<T, Error>
    {
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap(throwErrorOnBadStatus)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .mapError(Error.fromGenericError)
            .eraseToAnyPublisher()
    }

    static func post<T: Decodable>(url: URL, body: Data?, decoder: JSONDecoder)
        -> AnyPublisher<
            T, Error
        >
    {
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

    private static func throwErrorOnBadStatus(
        output: URLSession.DataTaskPublisher.Output
    ) throws -> URLSession.DataTaskPublisher.Output {
        guard let httpResponse = output.response as? HTTPURLResponse
        else {
            throw Http.Error.InvalidResponse(
                response: output.response,
                data: output.data
            )
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode <= 300
        else {
            throw Http.Error.BadStatus(
                status: httpResponse.statusCode,
                data: output.data
            )
        }

        return output
    }
}
