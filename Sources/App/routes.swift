import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  let elasticClient = ElasticsearchClient(host: "http://localhost", port: 9200)
  let recipeFinderController = RecipeFinderController(elasticClient: elasticClient)
  try router.register(collection: recipeFinderController)
}
