import Vapor
import VaporSMTPKit
import SMTPKitten

struct EmailVerifier {
    let emailTokenRepository: EmailTokenRepository
    let app: Application
    let eventLoop: EventLoop
    
    func verify(for user: User) -> EventLoopFuture<Void> {
        do {
            let token = RandomGenerator.getRandomString(32)
            let emailToken = try EmailToken(userID: user.requireID(), token: SHA256.hash(token))
            let verifyUrl = getVerificationURL(token: token)
            
            return emailTokenRepository.create(emailToken).flatMap {
                let email = Mail(
                    from: MailUser(name: app.config.emailName, email: app.config.emailAddress),
                    to: [ MailUser(name: user.fullName, email: user.email) ],
                    subject: "Your new mail server!",
                    contentType: .plain,
                    text: "Please confirm your email address using this link: \(verifyUrl)"
                )
                
                // don't wait for a mail send to succeed, it may take more than a second!
                _ = app.sendMail(email, withCredentials: app.config.smtpCredentials)
                    .flatMapError { error in
                        print("Can't send email to \(email.to.first!.email). Problem: \(error.localizedDescription)")
                        return eventLoop.makeFailedFuture(error)
                    }
                    .map {
                        print("Email sent to \(email.to.first!.email)")
                    }
                
                return eventLoop.makeSucceededFuture(())
                //.init(VerificationEmail(verifyUrl: verifyUrl), to: user.email))
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
            
        /*let emailToken = try EmailToken(userID: user.requireID(), token: SHA256.hash(token))
            let verifyUrl = url(token: token)
            return emailTokenRepository.create(emailToken).flatMap {
                self.queue.dispatch(EmailJob.self, .init(VerificationEmail(verifyUrl: verifyUrl), to: user.email))
            }
         */
    }
    
    private func getVerificationURL(token: String) -> String {
        #"\#(app.config.apiURL)/auth/email-verification?token=\#(token)"#
    }
}


extension Application {
    var emailVerifier: EmailVerifier {
        .init(emailTokenRepository: self.repositories.emailTokens, app: self, eventLoop: eventLoopGroup.next())
    }
}

extension Request {
    var emailVerifier: EmailVerifier {
        .init(emailTokenRepository: self.emailTokens, app: self.application, eventLoop: eventLoop)
    }
}

