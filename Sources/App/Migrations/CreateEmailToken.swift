import Fluent

struct CreateEmailToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("auth_email_tokens")
            .id()
            .field("user_id", .uuid, .required, .references("auth_users", "id", onDelete: .cascade))
            .field("token", .string, .required)
            .field("expires_at", .datetime, .required)
            .unique(on: "user_id")
            .unique(on: "token")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("auth_email_tokens").delete()
    }
}
