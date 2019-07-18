import Vapor
import HTTP

// MARK: Client
public final class ElasticsearchClient {

  private let scheme: String
  private let host: String
  private let port: Int
  private let username: String?
  private let password: String?

  public init(scheme: String = "http", host: String, port: Int = 9200, username: String? = nil, password: String? = nil) {
    self.scheme = scheme
    self.host = host
    self.port = port
    self.username = username
    self.password = password
  }

  private func sendRequest<D: Decodable>(_ request: HTTPRequest, to url: URLRepresentable, on container: Container) throws -> Future<D> {
    print("\nRequest:\n\n\(request)\n")
    return try sendRequest(request, to: url, on: container).flatMap { response in
      print("\nResponse:\n\n\(response)\n")
      switch response.http.status.code {
      case 200...299: return try ElasticsearchClient.jsonDecoder.decode(D.self, from: response.http, maxSize: 1_000_000, on: container)
      default: throw Abort(response.http.status)
      }
    }
  }

  private func sendRequest(_ request: HTTPRequest, to url: URLRepresentable, on container: Container) throws -> Future<Response> {
    return try container.client().send(
      request.method,
      headers: request.headers,
      to: url,
      beforeSend: { req in
        req.http.body = request.body
    })
  }
}

// MARK: - Helper
extension ElasticsearchClient {

  private func baseURL(path: String, queryItems: [URLQueryItem] = []) -> URL {
    var urlComponents = URLComponents()
    urlComponents.scheme = scheme
    urlComponents.host = host
    urlComponents.port = port
    urlComponents.path = path
    urlComponents.queryItems = queryItems

    guard let url = urlComponents.url else {
      fatalError("malformed url: \(urlComponents)")
    }
    return url
  }

  private static let jsonDecoder: JSONDecoder = {
    let jsonDecoder = JSONDecoder()
    return jsonDecoder
  }()

  private static let jsonEncoder: JSONEncoder = {
    let jsonEncoder = JSONEncoder()
    return jsonEncoder
  }()
}

// MARK: Requests
extension ElasticsearchClient {

  public func createDocument<Document: Encodable>(document: Document, in indexName: String, on container: Container) throws -> Future<ESCreateDocumentResponse> {
    let url = baseURL(path: "/\(indexName)/_doc")
    var request = try HTTPRequest(method: .POST, url: url, body: ElasticsearchClient.jsonEncoder.encode(document))
    request.contentType = .json
    return try sendRequest(request, to: url, on: container)
  }

  public func getDocument<Document: Decodable>(id: String, from indexName: String, on container: Container) throws -> Future<ESGetSingleDocumentResponse<Document>> {
    let url = baseURL(path: "/\(indexName)/_doc/\(id)")
    let request = HTTPRequest(method: .GET, url: url)
    return try sendRequest(request, to: url, on: container)
  }

  public func getAllDocuments<Document: Decodable>(from indexName: String, on container: Container) throws -> Future<ESGetMultipleDocumentsResponse<Document>> {
    let url = baseURL(path: "/\(indexName)/_search")
    let request = HTTPRequest(method: .GET, url: url)
    return try sendRequest(request, to: url, on: container)
  }

  public func searchDocuments<Document: Decodable>(from indexName: String, searchTerm: String, on container: Container) throws -> Future<ESGetMultipleDocumentsResponse<Document>> {
    let url = baseURL(
      path: "/\(indexName)/_search",
      queryItems: [URLQueryItem(name: "q", value: searchTerm)]
    )
    let request = HTTPRequest(method: .GET, url: url)
    return try sendRequest(request, to: url, on: container)
  }

  public func updateDocument<Document: Encodable>(document: Document, id: String, in indexName: String, on container: Container) throws -> Future<ESUpdateDocumentResponse> {
    let url = baseURL(path: "/\(indexName)/_doc/\(id)")
    var request = try HTTPRequest(method: .PUT, url: url, body: ElasticsearchClient.jsonEncoder.encode(document))
    request.contentType = .json
    return try sendRequest(request, to: url, on: container)
  }

  public func deleteDocument(id: String, from indexName: String, on container: Container) throws -> Future<ESDeleteDocumentResponse> {
    let url = baseURL(path: "/\(indexName)/_doc/\(id)")
    let request = HTTPRequest(method: .DELETE, url: url)
    return try sendRequest(request, to: url, on: container)
  }

  public func deleteIndex(_ indexName: String, on container: Container) throws -> Future<HTTPStatus> {
    let url = baseURL(path: "/\(indexName)")
    let request = HTTPRequest(method: .DELETE, url: url)
    return try sendRequest(request, to: url, on: container).map { response in
      return response.http.status
    }
  }
}
