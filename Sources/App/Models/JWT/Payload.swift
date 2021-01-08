import Vapor
import JWT

struct Payload: JWTPayload, Authenticatable {
    // User-releated stuff
    var userID: UUID
    var fullName: String?
    var email: String?
    var isAdmin: Bool?
    
    // JWT stuff
    var exp: ExpirationClaim = ExpirationClaim(value: Date().addingTimeInterval(Constants.ACCESS_TOKEN_LIFETIME))
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
    
    init(with user: User) throws {
        self.userID = try user.requireID()
        self.fullName = user.fullName
        self.email = user.email
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(Constants.ACCESS_TOKEN_LIFETIME))
    }
}
