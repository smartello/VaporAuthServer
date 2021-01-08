import Vapor
import SMTPKitten

struct PasswordResetter {
    let app: Application
    let repository: PasswordTokenRepository
    let eventLoop: EventLoop
    
    /// Sends a email to the user with a reset-password URL
    func reset(for user: User) -> EventLoopFuture<Void> {
        do {
            let token = RandomGenerator.getRandomString(32)
            let resetPasswordToken = try PasswordToken(userID: user.requireID(), token: SHA256.hash(token))
            let url = resetURL(for: token)
            //let email = ResetPasswordEmail(resetURL: url)
            return repository.create(resetPasswordToken).flatMap {
                let email = Mail(
                    from: MailUser(name: app.config.emailName, email: app.config.emailAddress),
                    to: [ MailUser(name: user.fullName, email: user.email) ],
                    subject: "Password reset",
                    contentType: .plain,
                    text: "Reset password link: \(url)"
                )
                
                //self.queue.dispatch(EmailJob.self, .init(email, to: user.email))
                _ = app.sendMail(email, withCredentials: app.config.smtpCredentials)
                    .flatMapError { error in
                        print("Can't send email to \(email.to.first!.email). Problem: \(error.localizedDescription)")
                        return eventLoop.makeFailedFuture(error)
                    }
                    .map {
                        print("Email sent to \(email.to.first!.email)")
                    }
                
                return eventLoop.makeSucceededFuture(())
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    private func resetURL(for token: String) -> String {
        "\(app.config.frontendURL)/auth/reset-password?token=\(token)"
    }
}

extension Request {
    var passwordResetter: PasswordResetter {
        .init(app: self.application, repository: self.passwordTokens, eventLoop: self.eventLoop)
    }
}
