import Vapor
import JWT

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.grouped(UserAuthenticator()).get("hello") { req -> String in
        let payload = try req.auth.require(Payload.self)
        
        //let token = req.headers.bearerAuthorization!.token
            //req.headers.first(name: "Token")!
        var verifiedString: String
        do {
            //var payload = try app.jwt.signers.verify(token, as: Payload.self)
            verifiedString = "Welcome \(payload.fullName ?? "anonymous")"
        } catch {
            verifiedString = "No access"
        }
        
        return "Hello, world! " + verifiedString
    }
    
    app.group("api") { auth in
        try! auth.register(collection: AuthenticationController())
    }
}
