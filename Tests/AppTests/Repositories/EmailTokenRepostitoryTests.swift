@testable import App
import Fluent
import FluentSQLiteDriver
import XCTVapor

final class EmailTokenRepositoryTests: XCTestCase {
    var app: Application!
    var repository: EmailTokenRepository!
    var user: User!
    
    override func setUpWithError() throws {
        app = Application(.testing)
        try configure(app)
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
        //app.db(.psql).
        repository = DatabaseEmailTokenRepository(database: app.db(.sqlite))
        try app.autoMigrate().wait()
        
        user = User(fullName: "Test", email: "test@test.com", passwordHash: "123")
    }
    
    override func tearDownWithError() throws {
        try app.autoRevert().wait()
        app.shutdown()
    }
    
    func testCreatingEmailToken() throws {
        try user.create(on: app.db).wait()
        let emailToken = EmailToken(userID: try user.requireID(), token: "emailToken")
        try repository.create(emailToken).wait()
        
        let count = try EmailToken.query(on: app.db).count().wait()
        XCTAssertEqual(count, 1)
    }
    
    func testFindingEmailTokenByToken() throws {
        try user.create(on: app.db).wait()
        let emailToken = EmailToken(userID: try user.requireID(), token: "123")
        try emailToken.create(on: app.db).wait()
        let found = try repository.find(token: "123").wait()
        XCTAssertNotNil(found)
    }
    
    func testDeleteEmailToken() throws {
        try user.create(on: app.db).wait()
        let emailToken = EmailToken(userID: try user.requireID(), token: "123")
        try emailToken.create(on: app.db).wait()
        try repository.delete(emailToken).wait()
        let count = try EmailToken.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }
    
    func testFindTokenByUserId() throws {
        try user.create(on: app.db).wait()
        let emailToken = EmailToken(userID: try user.requireID(), token: "123")
        try emailToken.create(on: app.db).wait()
        
        let tokenFound = try app.repositories.emailTokens.find(userID: try user.requireID()).wait()
        XCTAssertNotNil(tokenFound)
        XCTAssertEqual(tokenFound!.token, emailToken.token)
    }
}
    

