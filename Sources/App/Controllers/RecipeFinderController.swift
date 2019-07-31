/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

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
