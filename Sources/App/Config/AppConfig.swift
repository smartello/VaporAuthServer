import Vapor
import VaporSMTPKit

struct AppConfig {
    let frontendURL: String
    let apiURL: String
    let noReplyEmail: String
    let emailAddress: String
    let emailName: String
    let smtpCredentials: SMTPCredentials
    
    init(_ environment: Environment) {
        switch environment {
            case .testing: self = .dummy
            default: self = .environment
        }
    }
    
    init(frontendURL: String, apiURL: String, noReplyEmail: String, emailAddress: String, emailName: String, smtpCredentials: SMTPCredentials) {
        self.frontendURL = frontendURL
        self.apiURL = apiURL
        self.noReplyEmail = noReplyEmail
        self.emailAddress = emailAddress
        self.emailName = emailName
        self.smtpCredentials = smtpCredentials
    }
    
    static var environment: AppConfig {
        guard
            let frontendURL = Environment.get("SITE_FRONTEND_URL"),
            let apiURL = Environment.get("SITE_API_URL"),
            let noReplyEmail = Environment.get("NO_REPLY_EMAIL"),
            let emailAddress = Environment.get("EMAIL_ADDRESS"),
            let emailName = Environment.get("EMAIL_NAME"),
            
            let smtp_hostname = Environment.get("SMTP_SERVER_ADDRESS"),
            let smtp_port = Int(Environment.get("SMTP_SERVER_PORT") ?? ""),
            let smtp_email = Environment.get("EMAIL_ADDRESS"),
            let smtp_password = Environment.get("EMAIL_PASSWORD")
        else {
            fatalError("Please add app configuration to environment variables")
        }
        
        let smtpCredentials = SMTPCredentials(
            hostname: smtp_hostname,
            port: smtp_port,
            ssl: .startTLS(configuration: .default),
            email: smtp_email,
            password: smtp_password
        )
        
        return .init(frontendURL: frontendURL, apiURL: apiURL, noReplyEmail: noReplyEmail, emailAddress: emailAddress, emailName: emailName, smtpCredentials: smtpCredentials)
    }
    
    static var dummy: AppConfig {
        let smtpCredentials = SMTPCredentials(hostname: "", port: 25, ssl: .insecure, email: "", password: "")
        
        return .init(frontendURL: "", apiURL: "", noReplyEmail: "", emailAddress: "", emailName: "", smtpCredentials: smtpCredentials)
    }
}

extension Application {
    struct AppConfigKey: StorageKey {
        typealias Value = AppConfig
    }
    
    var config: AppConfig {
        get {
            storage[AppConfigKey.self] ?? .environment
        }
        set {
            storage[AppConfigKey.self] = newValue
        }
    }
}
