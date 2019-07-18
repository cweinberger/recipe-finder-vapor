public struct ESCreateDocumentResponse: Decodable {
  let id: String
  let index: String
  let version: Int?
  let result: String

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case index = "_index"
    case version = "_version"
    case result
  }
}

public typealias ESDeleteDocumentResponse = ESCreateDocumentResponse
public typealias ESUpdateDocumentResponse = ESCreateDocumentResponse
