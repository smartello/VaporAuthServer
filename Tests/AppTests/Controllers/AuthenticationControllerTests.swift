
@testable import App
import Fluent
import FluentSQLiteDriver
import XCTVapor

final class AuthenticationControllerTests: XCTestCase {
    var app: Application!
    var testRealm: TestRealm?
    
    override func setUpWithError() throws {
        app = Application(.testing)
        try configure(app)
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
        testRealm = try TestRealm(app: app)
        try testRealm!.app.autoMigrate().wait()
        //user = User(fullName: "Test User", email: "test@test.com", passwordHash: "123")
    }
    
    override func tearDownWithError() throws {
        try testRealm!.app.migrator.revertAllBatches().wait()
        testRealm!.app.shutdown()
    }
    
    func testRegisterFailureShortPassword() throws {
        //short password
        let reqContent = RegisterRequest(fullName: "Test User", email: "test@test.com", password: "1", confirmPassword: "1")
        try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
            try req.content.encode(reqContent)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            let error = try res.content.decode(ErrorResponse.self)
            XCTAssertEqual(error.error, true)
        })
    }
        
    func testRegisterFailureShortName() throws {
        //short fullName
        let reqContent = RegisterRequest(fullName: "T", email: "test@test.com", password: "12345678", confirmPassword: "12345678")
        try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
            try req.content.encode(reqContent)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            let error = try res.content.decode(ErrorResponse.self)
            XCTAssertEqual(error.error, true)
        })
    }
    
    func testRegisterFailureWrongEmail() throws {
        //short email
        let reqContent = RegisterRequest(fullName: "Test User", email: "test@test", password: "12345678", confirmPassword: "12345678")
        try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
            try req.content.encode(reqContent)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            let error = try res.content.decode(ErrorResponse.self)
            XCTAssertEqual(error.error, true)
        })
    }
     
    func testRegisterFailurePasswordMismatch() throws {
        //password mismatch
        let reqContent = RegisterRequest(fullName: "Test User", email: "test@test.com", password: "12345678", confirmPassword: "87654321")
        try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
            try req.content.encode(reqContent)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            let error = try res.content.decode(ErrorResponse.self)
            XCTAssertEqual(error.error, true)
            XCTAssertEqual(error.reason, AuthenticationError.passwordsDontMatch.reason)
        })
    }
    
    func testRegister() throws {
        let userEmail = "test@test.com"
        
        let reqContent = RegisterRequest(fullName: "Test User", email: userEmail, password: "12345678", confirmPassword: "12345678")
        
        try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
            try req.content.encode(reqContent)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            
            //assume token has been sent
            let user = try! testRealm!.app.repositories.users.find(email: userEmail).wait()!
            let emailToken = try! testRealm!.app.repositories.emailTokens.find(userID: user.id!).wait()!
            try testRealm!.app.test(.GET, "/api/emailVerification?token=\(emailToken.token)", afterResponse: {res in
                //token must be hashed hence must not find it
                XCTAssertEqual(res.status, .notFound)
            })
            
            let newToken: String = "SomeRandomText"
            emailToken.token = SHA256.hash(newToken)
            try! emailToken.update(on: testRealm!.app.db).wait()
            
            try testRealm!.app.test(.GET, "/api/emailVerification?token=\(newToken)", afterResponse: {res in
                XCTAssertEqual(res.status, .ok)
            })
            
            // send the second request that should fail
            let reqContent = RegisterRequest(fullName: "Test User", email: userEmail, password: "12345678", confirmPassword: "12345678")
            try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
                try req.content.encode(reqContent)
            }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
                let error = try res.content.decode(ErrorResponse.self)
                XCTAssertEqual(error.error, true)
                XCTAssertEqual(error.reason, AuthenticationError.emailAlreadyExists.reason)
            })
        })
    }
    
    func testLogin() throws {
        let userEmail = "login@test.com"
        let password = "12345678"
        
        let reqContent = RegisterRequest(fullName: "Test User", email: userEmail, password: password, confirmPassword: password)
        
        try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
            try req.content.encode(reqContent)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            
            let newToken: String = "SomeRandomText"
            let user = try! testRealm!.app.repositories.users.find(email: userEmail).wait()!
            let emailToken = try! testRealm!.app.repositories.emailTokens.find(userID: user.id!).wait()!
            emailToken.token = SHA256.hash(newToken)
            try! emailToken.update(on: testRealm!.app.db).wait()
            try testRealm!.app.test(.GET, "/api/emailVerification?token=\(newToken)", afterResponse: {res in
                XCTAssertEqual(res.status, .ok)
                
                let loginReqContent = LoginRequest(email: userEmail, password: password)
                try testRealm!.app.test(.POST, "/api/login", beforeRequest: { req in
                    try req.content.encode(loginReqContent)
                }, afterResponse: {res in
                    XCTAssertEqual(res.status, .ok)
                })
                
                let loginFailureReqContent = LoginRequest(email: userEmail, password: "1234")
                try testRealm!.app.test(.POST, "/api/login", beforeRequest: { req in
                    try req.content.encode(loginFailureReqContent)
                }, afterResponse: {res in
                    XCTAssertEqual(res.status, .unauthorized)
                    let error = try res.content.decode(ErrorResponse.self)
                    XCTAssertEqual(error.error, true)
                    XCTAssertEqual(error.reason, AuthenticationError.invalidEmailOrPassword.reason)
                })
            })
        })
    }
}
