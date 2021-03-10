import Foundation
import ApolloCodegenLib
import ArgumentParser

/// The sub-command to download a schema from a provided endpoint.
struct DownloadSchema: ParsableCommand {
    // MARK: Flags, Options and Arguments

    @Option(
        name: [.customLong("ts-cli-output-dir"), .short],
        help: "The directory that the TypeScript CLI should be downloaded to.",
        completion: .directory
    )
    var typescriptCLIOutputDir: String

    @Option(
        name: [.customLong("output-dir"), .short],
        help: "The directory where the schema should be downloaded to.",
        completion: .directory
    )
    var outputDir: String

    @Argument(
        help: "The GraphQL endpoint (URL) the schema should be downloaded from.",
        transform: transformToURL(from:)
    )
    var endpoint: URL = URL(string: "http://localhost:4000/graphql")!

    // MARK: Config

    static var configuration = CommandConfiguration(
        commandName: "download-schema",
        abstract: "Downloads the GraphQL schema."
    )

    // MARK: Run 🏃

    func run() throws {
        let fileManager = FileManager.default
        let outputDir = fileManager.makeRelativeToCurrentDirectory(path: self.outputDir)
        let typescriptCLIOutputDir = fileManager.makeRelativeToCurrentDirectory(path: self.typescriptCLIOutputDir)

        print("-o: \(outputDir)")
        print("-t: \(typescriptCLIOutputDir)")

        // Make sure the folder is created before trying to download something to it.
        try fileManager.apollo.createFolderIfNeeded(at: outputDir)
        try fileManager.apollo.createFolderIfNeeded(at: typescriptCLIOutputDir)

        // Create an options object for downloading the schema. Provided code will download the schema via an
        // introspection query to the provided URL as JSON to a file called "schema.json". For full options check out
        // https://www.apollographql.com/docs/ios/api/ApolloCodegenLib/structs/ApolloSchemaOptions/
        let schemaDownloadOptions = ApolloSchemaOptions(
            downloadMethod: .introspection(endpointURL: endpoint),
            outputFolderURL: outputDir
        )

        // Actually attempt to download the schema.
        try ApolloSchemaDownloader.run(
            with: typescriptCLIOutputDir,
            options: schemaDownloadOptions
        )
    }
}
