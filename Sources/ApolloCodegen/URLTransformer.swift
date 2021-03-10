import Foundation

struct InvalidURLStringError: Error {
    let value: String
}

func transformToURL(from string: String) throws -> URL {
    guard let url = URL(string: string) else {
        throw InvalidURLStringError(value: string)
    }
    return url
}
