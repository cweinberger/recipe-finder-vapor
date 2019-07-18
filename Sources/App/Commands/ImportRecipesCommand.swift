import Vapor

public struct ImportRecipesCommand: Command {

  public var options: [CommandOption] = []

  public var arguments: [CommandArgument] {
    return [.argument(name: "fileName")]
  }

  public var help: [String] {
    return ["Imports the recipes found at `fileName` (in Resources) into Elasticsearch `recipes` index."]
  }

  public func run(using context: CommandContext) throws -> Future<Void> {
    guard let fileName = try? context.argument("fileName") else {
      throw Abort(.badRequest, reason: "fileName argument is missing")
    }

    let directoryConfig = DirectoryConfig.detect()
    let resourcesDir = "/Resources"

    let fileURL = URL(fileURLWithPath: directoryConfig.workDir)
      .appendingPathComponent(resourcesDir)
      .appendingPathComponent(fileName, isDirectory: false)

    guard let data = try? Data(contentsOf: fileURL) else {
      throw Abort(.badRequest, reason: "Could not read file: \(fileURL)")
    }

    guard let recipes = try? JSONDecoder().decode([Recipe].self, from: data) else {
      throw Abort(.badRequest, reason: "Could not parse JSON into recipes")
    }

    let elasticClient = ElasticsearchClient(host: "http://localhost", port: 9200)

    let lazyFutures: [LazyFuture<ESCreateDocumentResponse>] = recipes.map { recipe in
      return {
        return try elasticClient.createDocument(document: recipe, in: "recipes", on: context.container)
      }
    }

    return lazyFutures
      .syncFlatten(on: context.container)
      .do { _ in print("Import done") }
      .transform(to: ())
  }
}
