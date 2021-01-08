import Vapor

struct UserDTO: Content {
    let id: UUID?
    let fullName: String
    let email: String
    
    init(id: UUID? = nil, fullName: String, email: String) {
        self.id = id
        self.fullName = fullName
        self.email = email
    }
    
    init(from user: User) {
        self.init(id: user.id, fullName: user.fullName, email: user.email)
    }
}


