import Combine
import Foundation
import Swift

enum Http {
    enum Error: Swift.Error {
        case sessionError(error: URLError)
        case badBody(decodingError: Swift.DecodingError)
        case badStatus(status: Int, data: Data)
        case invalidResponse(response: URLResponse, data: Data)
        case other(Swift.Error)

        static func fromGenericError(_ error: Swift.Error) -> Error {
            switch error {
            case (let decodingError) as Swift.DecodingError:
                return .badBody(decodingError: decodingError)
            case (let urlError) as URLError:
                return .sessionError(error: urlError)
            case (let httpError) as Error:
                return httpError
            default:
                return .other(error)
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
        -> AnyPublisher<T, Error>
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
            throw Http.Error.invalidResponse(
                response: output.response,
                data: output.data
            )
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode <= 300
        else {
            throw Http.Error.badStatus(
                status: httpResponse.statusCode,
                data: output.data
            )
        }

        return output
    }
}
