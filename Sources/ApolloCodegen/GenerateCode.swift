import Foundation
import ApolloCodegenLib
import ArgumentParser

/// The sub-command to actually generate code.
struct GenerateCode: ParsableCommand {
    // MARK: Custom Option Types

    enum AccessModifier: String, ExpressibleByArgument, CaseIterable {
        case `public`
        case `internal`
        case none
    }

    enum CustomScalarFormat: String, ExpressibleByArgument, CaseIterable {
      /// Uses a default type instead of a custom scalar.
      case none
      /// Use your own types for custom scalars.
      case passthrough
      /// Use your own types for custom scalars with a prefix.
      case passthroughWithPrefix
    }

    enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
        case single
        case multiple
    }

    // MARK: Flags, Options and Arguments

    @Option(
        name: [.customLong("ts-cli-dir"), .short],
        help: "The directory that the TypeScript CLI can be found.",
        completion: .directory
    )
    var typescriptCLIDir: String

    @Option(
        name: .shortAndLong,
        help: "The path to the schema.json file",
        completion: .file(extensions: ["json"])
    )
    var schema: String

    @Option(
        name: [.customLong("output-format"), .customShort("f")],
        help: "The output style. Defaults to a single file."
    )
    var outputFormat: OutputFormat = .single

    @Option(
        name: .shortAndLong,
        help: "The path to the output file or directory, depending on the value of `--output-format`."
    )
    var output: String

    @Option(
        name: .shortAndLong,
        help: "The Swift access modifier that should be used."
    )
    var accessModifier: AccessModifier = .public

    @Option(
        name: .long,
        help: "The namespace that should be used for the generated types."
    )
    var namespace: String?

    @Option(
        name: .long,
        help: "How custom scalar types should be handled."
    )
    var customScalarFormat: CustomScalarFormat = .none

    @Option(
        name: .long,
        help: "The prefix to use for custom scalar types when `--custom-scalar-format` is set to `passthroughWithPrefix`."
    )
    var customScalarPrefix: String?

    @Option(
        name: .long,
        help: "Parse all input files, but only output generated code for the file at this path if non-nil.",
        completion: .file(extensions: ["graphql"])
    )
    var only: String?

    @Option(
        name: .long,
        help: """
        Path to an operation id JSON map file. If specified, also stores the operation ids (hashes) as properties on
        operation types.
        """,
        completion: .file(extensions: ["json"])
    )
    var operationIDsPath: String?

    @Flag(
        name: .long,
        help: "Omit deprecated enum cases from the generated code."
    )
    var omitDeprecatedEnumCases = false

    @Flag(
        name: .long,
        help: "[EXPERIMENTAL] Use the Swift codegen subsystem instead of the TypeScript CLI."
    )
    var useSwiftCodegenEnginer = false

    @Argument(help: "The path or glob pattern for the `.graphql` files that should be included.")
    var includes: String = "./**/*.graphql"

    // MARK: Config

    static var configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generates Swift code from a GraphQL schema and operations (`*.graphql` files).",
        discussion: """
        If outputting a single file the `--output` option should be the path to the file.
        E.g. `path/to/file.swift`

        If outputting multiple files - one per “operation” - then the `--output` option should
        be to a directory. E.g. `path/to/output/dir/`
        """
    )

    // MARK: Run 🏃

    func run() throws {
        let fileManager = FileManager.default
        let schema = fileManager.makeRelativeToCurrentDirectory(path: self.schema)
        let output = fileManager.makeRelativeToCurrentDirectory(path: self.output)
        let typescriptCLIDir = fileManager.makeRelativeToCurrentDirectory(path: self.typescriptCLIDir)

        let customScalarFormat = try ApolloCodegenOptions.CustomScalarFormat(
            customScalarFormat: self.customScalarFormat,
            prefix: customScalarPrefix
        )
        let codegenOptions = ApolloCodegenOptions(
            codegenEngine: useSwiftCodegenEnginer ? .swiftExperimental : .typescript,
            includes: includes,
            modifier: ApolloCodegenOptions.AccessModifier(accessModifier: accessModifier),
            namespace: namespace,
            omitDeprecatedEnumCases: omitDeprecatedEnumCases,
            only: onlyURL(using: fileManager),
            operationIDsURL: operationIDsURL(using: fileManager),
            outputFormat: ApolloCodegenOptions.OutputFormat(outputFormat: outputFormat, output: output),
            customScalarFormat: customScalarFormat,
            urlToSchemaFile: schema
        )

        // Make sure the folder exists before trying to generate code.
        try fileManager.apollo.createFolderIfNeeded(at: output)

        // Actually attempt to generate code.
        try ApolloCodegen.run(
            from: output,
            with: typescriptCLIDir,
            options: codegenOptions
        )
    }

    private func onlyURL(using fileManager: FileManager) -> URL? {
        if let path = only {
             return fileManager.makeRelativeToCurrentDirectory(path: path)
        } else {
            return nil
        }
    }

    private func operationIDsURL(using fileManager: FileManager) -> URL? {
        if let path = operationIDsPath {
             return fileManager.makeRelativeToCurrentDirectory(path: path)
        } else {
            return nil
        }
    }
}

// MARK: - Converting Types

extension ApolloCodegenOptions.AccessModifier {
    init(accessModifier: GenerateCode.AccessModifier) {
        switch accessModifier {
        case .public: self = .public
        case .internal: self = .internal
        case .none: self = .none
        }
    }
}

extension ApolloCodegenOptions.CustomScalarFormat {
    struct CustomScalarMissingPrefixError: Error {}

    init(customScalarFormat: GenerateCode.CustomScalarFormat, prefix: String?) throws {
        switch customScalarFormat {
        case .none: self = .none
        case .passthrough: self = .passthrough
        case .passthroughWithPrefix:
            guard let prefix = prefix else {
                throw CustomScalarMissingPrefixError()
            }
            self = .passthroughWithPrefix(prefix)
        }
    }
}

extension ApolloCodegenOptions.OutputFormat {
    init(outputFormat: GenerateCode.OutputFormat, output: URL) {
        switch outputFormat {
        case .single:
            self = .singleFile(atFileURL: output)
        case .multiple:
            self = .multipleFiles(inFolderAtURL: output)
        }
    }
}
