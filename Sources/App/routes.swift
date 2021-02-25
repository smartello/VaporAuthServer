import Vapor
import JWT

func routes(_ app: Application) throws {
    /*app.get { req in
        return "It works!"
    }

    app.grouped(UserAuthenticator()).get("hello") { req -> String in
        let payload = try req.auth.require(Payload.self)
        
        //let token = req.headers.bearerAuthorization!.token
        //req.headers.first(name: "Token")!
        let verifiedString = "Welcome \(payload.fullName ?? "anonymous")"
        
        return "Hello, world! " + verifiedString
    }
    */
    app.group("api") { auth in
        try! auth.register(collection: AuthenticationController())
    }
}
