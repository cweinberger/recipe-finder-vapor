import Vapor

final class RecipeFinderController {
  let elasticClient: ElasticsearchClient

  init(elasticClient: ElasticsearchClient) {
    self.elasticClient = elasticClient
  }
}

extension RecipeFinderController: RouteCollection {

  func boot(router: Router) throws {
    let routes = router.grouped("api", "recipes")
    routes.post(Recipe.self, use: createHandler)
    routes.get(use: getAllHandler)
    routes.get(String.parameter, use: getSingleHandler)
    routes.put(Recipe.self, at: String.parameter, use: updateHandler)
    routes.delete(String.parameter, use: deleteHandler)
    routes.get("search", use: searchHandler)
  }
  
  func createHandler(_ req: Request, recipe: Recipe) throws -> Future<Recipe> {
    return try elasticClient
      .createDocument(document: recipe, in: "recipes", on: req).map { response in
        recipe.id = response.id
        return recipe
    }
  }

  func getAllHandler(_ req: Request) throws -> Future<[Recipe]> {
    return try elasticClient
      .getAllDocuments(from: "recipes", on: req)
      .map { (response: ESGetMultipleDocumentsResponse<Recipe>) in
        return response.hits.hits.map { doc in
          let recipe = doc.source
          recipe.id = doc.id
          return recipe
        }
    }
  }

  func getSingleHandler(_ req: Request) throws -> Future<Recipe> {
    let id: String = try req.parameters.next()
    return try elasticClient
      .getDocument(id: id, from: "recipes", on: req)
      .map { (response: ESGetSingleDocumentResponse<Recipe>) in
        return response.source
    }
  }

  func updateHandler(_ req: Request, recipe: Recipe) throws -> Future<Recipe> {
    let id: String = try req.parameters.next()
    return try elasticClient.updateDocument(document: recipe, id: id, in: "recipes", on: req).map { response in
      return recipe
    }
  }

  func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    let id: String = try req.parameters.next()
    return try elasticClient.deleteDocument(id: id, from: "recipes", on: req).map { response in
      return .ok
    }
  }

  func searchHandler(_ req: Request) throws -> Future<[Recipe]> {
    guard let searchTerm = req.query[String.self, at: "term"] else {
      throw Abort(.badRequest, reason: "`term` is mandatory")
    }
    return try elasticClient
      .searchDocuments(from: "recipes", searchTerm: searchTerm, on: req)
      .map { (response: ESGetMultipleDocumentsResponse<Recipe>) in
        return response.hits.hits.map { doc in
          let recipe = doc.source
          recipe.id = doc.id
          return recipe
        }
    }
  }
}
