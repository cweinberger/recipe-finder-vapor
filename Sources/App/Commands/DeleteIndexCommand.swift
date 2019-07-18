import Vapor

public struct DeleteIndexCommand: Command {

  public var options: [CommandOption] = []

  public var arguments: [CommandArgument] {
    return [.argument(name: "indexName")]
  }

  public var help: [String] {
    return ["Deletes the specified index from Elasticsearch"]
  }

  public func run(using context: CommandContext) throws -> Future<Void> {
    guard let indexName = try? context.argument("indexName") else {
      throw Abort(.badRequest, reason: "indexName argument is missing")
    }

    let elasticClient = ElasticsearchClient(host: "http://localhost", port: 9200)
    return try elasticClient.deleteIndex(indexName, on: context.container).map { response in
      if response == .ok {
        print("Deleted index with name: `\(indexName)`")
      } else if response == .notFound {
        print("Could not find index with name: `\(indexName)`")
      } else {
        print("Delete index response: \(response)")
      }
    }.transform(to: ())
  }
}
