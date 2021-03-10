import Foundation
import ApolloCodegenLib
import ArgumentParser

struct ApolloCodegenCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: """
        A utility for performing Apollo GraphQL related tasks.

        Make sure the CLI version matches the version of the Apollo runtime your project is using.
        """,
        version: "0.42.0",
        subcommands: [DownloadSchema.self, GenerateCode.self]
    )
}

ApolloCodegenCLI.main()
