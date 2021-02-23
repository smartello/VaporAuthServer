
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
        let reqContent = RegisterRequest(fullName: "Test User", email: "test@test.com", password: "12345678", confirmPassword: "12345678")
        
        try testRealm!.app.test(.POST, "/api/register", beforeRequest: { req in
            try req.content.encode(reqContent)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            
        })
    }
}
