@testable import App
import Fluent
import XCTVapor
import VaporSMTPKit

class TestRealm {
    let app: Application
    
    // Repositories
    private var tokenRepository: TestRefreshTokenRepository
    private var userRepository: TestUserRepository
    private var emailTokenRepository: TestEmailTokenRepository
    private var passwordTokenRepository: TestPasswordTokenRepository
    
    private var refreshTokens: [RefreshToken] = []
    private var users: [User] = []
    private var emailTokens: [EmailToken] = []
    private var passwordTokens: [PasswordToken] = []
    
    init(app: Application) throws {
        self.app = app
        
        try app.jwt.signers.use(.es256(key: .generate()))
        
        self.tokenRepository = TestRefreshTokenRepository(tokens: refreshTokens, eventLoop: app.eventLoopGroup.next())
        self.userRepository = TestUserRepository(users: users, eventLoop: app.eventLoopGroup.next())
        self.emailTokenRepository = TestEmailTokenRepository(tokens: emailTokens, eventLoop: app.eventLoopGroup.next())
        self.passwordTokenRepository = TestPasswordTokenRepository(tokens: passwordTokens, eventLoop: app.eventLoopGroup.next())
        
        //app.repositories.use { _ in self.tokenRepository }
        //app.repositories.use { _ in self.userRepository }
        //app.repositories.use { _ in self.emailTokenRepository }
        //app.repositories.use { _ in self.passwordTokenRepository }
        
        let smtpCredentials = SMTPCredentials(
            hostname: "mail.local",
            port: 587,
            ssl: .startTLS(configuration: .default),
            email: "auth@testing.local",
            password: "password"
        )
        
        app.config = .init(frontendURL: "http://frontend.local", apiURL: "http://api.local", noReplyEmail: "no-reply@testing.local", emailAddress: "auth@testing.local", emailName: "auth@testing.local", smtpCredentials: smtpCredentials)
    }
}


