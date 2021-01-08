import Vapor
import Fluent
import JWT

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("register", use: register)
        routes.post("login", use: login)
        
        routes.group("email-verification") { emailVerificationRoutes in
            //emailVerificationRoutes.post("", use: sendEmailVerification)
            emailVerificationRoutes.get("", use: verifyEmail)
        }
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
                    .flatMap { req.emailVerifier.verify(for: user) }
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
        
        return req.users
            .find(email: loginRequest.email)
            .unwrap(or: AuthenticationError.invalidEmailOrPassword)
            .guard({ $0.isEmailVerified }, else: AuthenticationError.emailIsNotVerified)
            .flatMap { user -> EventLoopFuture<User> in
                return req.password
                    .async
                    .verify(loginRequest.password, created: user.passwordHash)
                    .guard({ $0 == true }, else: AuthenticationError.invalidEmailOrPassword)
                    .transform(to: user)
        }
        .flatMap { user -> EventLoopFuture<User> in
            do {
                return try req.refreshTokens.delete(for: user.requireID()).transform(to: user)
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
        .flatMap { user in
            do {
                let token = RandomGenerator.getRandomString(32)
                let refreshToken = try RefreshToken(token: SHA256.hash(token), userID: user.requireID())
                
                return req.refreshTokens
                    .create(refreshToken)
                    .flatMapThrowing {
                        try LoginResponse(
                            user: UserDTO(from: user),
                            accessToken: req.jwt.sign(Payload(with: user)),
                            refreshToken: token
                        )
                }
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    private func verifyEmail(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let token = try req.query.get(String.self, at: "token")
        
        let hashedToken = SHA256.hash(token)
        
        return req.emailTokens
            .find(token: hashedToken)
            .unwrap(or: AuthenticationError.emailTokenNotFound)
            .flatMap { req.emailTokens.delete($0).transform(to: $0) }
            .guard({ $0.expiresAt > Date() },
                   else: AuthenticationError.emailTokenHasExpired)
            .flatMap {
                req.users.set(\.$isEmailVerified, to: true, for: $0.$user.id)
        }
        .transform(to: .ok)
    }
}
        
