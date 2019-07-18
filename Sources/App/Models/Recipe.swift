import Vapor

final class Recipe: Codable {
  var id: String?
  var name: String
  var description: String
  var instructions: String
  var ingredients: [String]
}

extension Recipe: Content {}
