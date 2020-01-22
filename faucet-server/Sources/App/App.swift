import Vapor
import MySQL
import Fluent
import FluentMySQL
import SwiftyBeaverVapor
import SwiftyBeaver

public class App {
    private var app: Application!

    public init(_ env: Environment) throws {
        var config = Config.default()
        var env = env
        var services = Services.default()
        try configure(&config, &env, &services)
        app = try Application(config: config, environment: env, services: services)
    }

    public func run() throws {
        try app.run()
    }

    private func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
        try env.configure()

        /// Register routes to the router
        let router = EngineRouter.default()
        try setupRoutes(router)
        services.register(router, as: Router.self)

        /// Register middleware
        var middlewares = MiddlewareConfig()
        middlewares.use(ErrorMiddleware.self)
        services.register(middlewares)

        /// Register the configured MySQL database to the database config.
        try services.register(FluentMySQLProvider())
        let dbConfig = MySQLDatabaseConfig(
            hostname: Environment.Database.hostname,
            port: Environment.Database.port,
            username: Environment.Database.username,
            password: Environment.Database.password,
            database: Environment.Database.database,
            transport: .unverifiedTLS
        )
        let mysql = MySQLDatabase(config: dbConfig)
        var databases = DatabasesConfig()
        databases.add(database: mysql, as: .mysql)
        services.register(databases)

        /// Configure migrations
        var migrations = MigrationConfig()
        migrations.add(model: User.self, database: .mysql)
        migrations.add(model: Auth.self, database: .mysql)
        migrations.add(model: Faucet.self, database: .mysql)
        services.register(migrations)

        var middlewaresConfig = MiddlewareConfig()
        middlewaresConfig.use(APIErrorMiddleware(environment: env, specializations: [ModelNotFound()]))
        services.register(middlewaresConfig)

        let consoleDestination = ConsoleDestination()
        let fileDestination = FileDestination()
        fileDestination.logFileURL = URL(string: "file:///tmp/faucet.log")!
        try services.register(SwiftyBeaverProvider(destinations: [consoleDestination, fileDestination]))
        config.prefer(SwiftyBeaverVapor.self, for: Logger.self)

        /// Configure command
        var commandConfig = CommandConfig.default()
        commandConfig.useFluentCommands()
        services.register(commandConfig)
    }

    private func setupRoutes(_ router: Router) throws {
        router.get { req in
            return "Welcome!"
        }
        try router.register(collection: AuthorizationController())
        try router.register(collection: CKBController())
    }
}
