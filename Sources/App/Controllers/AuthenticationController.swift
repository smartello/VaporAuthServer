import Vapor
import Fluent
import JWT
import VaporSMTPKit
import SMTPKitten

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("register", use: register)
        routes.post("login", use: login)
    }
    
    func register(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try RegisterRequest.validate(content: req)
        let registerRequest = try req.content.decode(RegisterRequest.self)
        guard registerRequest.password == registerRequest.confirmPassword else {
            throw AuthenticationError.passwordsDontMatch
        }
        
        return req.password
            .async
            .hash(registerRequest.password)
            .flatMapThrowing { try User(from: registerRequest, hash: $0) }
            .flatMap { user in
                req.users.create(user)
                    .flatMap {
                        let email = Mail(
                            from: MailUser(name: req.application.config.emailName, email: req.application.config.emailAddress),
                            to: [ MailUser(name: user.fullName, email: user.email) ],
                            subject: "Your new mail server!",
                            contentType: .plain,
                            text: "You've set up mail!"
                        )
                        
                        return req.application.sendMail(email, withCredentials: req.application.config.smtpCredentials)
                            .flatMapError { error in
                                print("Can't send email to \(email.to.first!.email). Problem: \(error.localizedDescription)")
                                return req.eventLoop.makeFailedFuture(error)
                            }
                            .map {
                                print("Email sent to \(email.to.first!.email)")
                            }
                    }
                    .flatMapErrorThrowing {
                        if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                            throw AuthenticationError.emailAlreadyExists
                        }
                        throw $0
                    }
                    
        }
        .transform(to: .created)
    }
    
    func login(_ req: Request) throws -> EventLoopFuture<LoginResponse>  {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        var payload = Payload()
        payload.fullName = "John Doe"
        
        let response = LoginResponse(user: UserDTO(fullName: "John Doe", email: "test@aa.ok"), accessToken: try req.jwt.sign(payload, kid: JWKIdentifier("Auth")), refreshToken: "1")
        
        return req.eventLoop.makeSucceededFuture(response)
    }
    
    
}
        
