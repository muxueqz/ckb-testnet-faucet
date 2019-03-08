import Vapor
import SQLite

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    router.get("verify", use: verify)
    router.get("auth/callback", use: authCallback)
    router.get("getTestToken", use: getTestToken)
}
