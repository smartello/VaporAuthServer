import Vapor
import JWT
import FluentPostgresDriver
import VaporSMTPKit

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // MARK: JWK
    //generated with https://mkjwk.org
    let rsaJWK = try JWK(json: """
{
    "p": "x53hpLeCd1OSC_1YZvMJhCL9fguQsJt_kgJwb8GNsJSu2gtNnwAN1cHmZIbNdD9sarqj0vhRuE8lNqUC9kI6eG5lcssfSHGpeyNT2N9nHQz4QmY8AQI6n7s1TjymQj8cbeyIj10-E8P5nJBnaacdrPA9dUKTyv7FFcdgHxvlX5s",
    "kty": "RSA",
    "q": "qMyj1CZ7Spgepf5nClQ1oQLiNHp-OpkVOuHlSrxEP4TWTgld-EOoM50SAzRrnHpjFAqu0p-eglEZiC00ouPks7hn-96UFwDk9n7Km-HMCYf4RLol-TJ9yLtxSWw1fLj_o1CLPqpytmxhcRNn_I7n4KtaWZFDAHLn3rQtmmui6Xc",
    "d": "JD8x0ieFGg6tMfy3SlcNlLnNv8qFWn6o4gg-dWdBQEVqOabMb0ZZQy3rGzqdo52RSulNVR8IlbcdqKTOv7lv335BSa3FopBub-bxuN-ghjqRMM5JODRQRKeXB09azoJqUgLYbOMnYCBGcdhvXyWk7StP8iuMje2t-Hvb8GFwdoO2WfqvesgBtyYXx39rUWZg3saJyc8HWtBIWb0lk7ji9Du2dYZTlQaxQ6w0sjrzBczg61fm4lmiegzXa5jTHYpw8bPDpCTgK0V5Hzv93Rhej7LsROC3TJ6t_olNYgmF9GNrFuTfy6GjoBfcNmgo7sUGr3a41EgZACXOV5K8qL1mAQ",
    "e": "AQAB",
    "kid": "Auth",
    "qi": "veqiQW8XQ39jFc1ui2ZOvmns4AWArf7SZL2QiGl53jHYzK4QfrRnE6irLeEF1DnCE-efDYaQ-QILOA69Am5fClOrJ7k3dUoGRKY8cCjc8ud-su9OPbn_Up2iT3drJ5sCUcBFIBBmTyoBdPNt10gTF7j0Qh0-SIt-VWLhOaRHjP4",
    "dp": "rClL8i9fc6D9JiATvX7BZ1hyPuKkoN0MEpbN-GT72h7yCxaSlJ6MUB7SoULuMeN9kzNzlcIbYRXJp657tn56RWIZVv8-9NEq9gwLBdHv8cs81q-r8sbEXv0sRVTjo-EgmOHXCabGom90egbFWgcK_huZNef85agDvPveuBXsJx8",
    "alg": "RS256",
    "dq": "TOVEcJ3DJp0bwSSejg8Eiz_ECoIOxOT9zeAgUyZmtMTv14be3vz7P9_616jmqNb8EaI4N8ztKZKGXgmx486LXe_QtuWTctM-eqgR5mc7StA9IhnmuJnuwSXamscHqrSgCCbl9_sv3LiMvzVG9r-nFCsbMphA_JBb3pEYATOteEs",
    "n": "g58totscKgoWtFbTnikwvAUHK-sxi9u8YOx9PkPz2feGV2PxycxgXLKV6r9x52ve_ErImgw5CCp80byzWuVw68ZdnbeX1aV2BNegOXAFE3K3FVNu2AWRJgMdtwM1E3pzlJy-aFWe6WnaIR5tuX1VmaYWNJatTCxskddwSX6md6rtNL-0ofShOlNnSFUK73DhIs01epvfFvWGrfHcUcUYrtWmDkUjdDJ-n9eduSzicEb3ZebghOHFzH2hqgzpznv5Qo6kj_L66RrC8sJF56SQdIG4CA5nyQD0rec3I7yKSX2mCY8iPF0I2gzuEbdVSbzHizc-pKWCB3InSEc0BLmEDQ"
}
""")
    
    try app.jwt.signers.use(jwk: rsaJWK)
    
    // MARK: Database
    // Configure PostgreSQL database
    app.databases.use(
        .postgres(
            hostname: Environment.get("POSTGRES_HOSTNAME") ?? "localhost",
            username: Environment.get("POSTGRES_USERNAME") ?? "docker",
            password: Environment.get("POSTGRES_PASSWORD") ?? "docker",
            database: Environment.get("POSTGRES_DATABASE") ?? "auth"
    ), as: .psql)
    
    app.migrations.add([
        CreateUser(),
        CreateRefreshToken(),
        CreateEmailToken()
    ])
    
    // MARK: Repositories
    app.repositories.use(.database)
    
    // MARK: App Config
    app.config = .environment
    
    //var env = try Environment.detect()
    //try LoggingSystem.bootstrap(from: &env)

    //let app = Application(env)
    //defer { app.shutdown() }
/*
    app.smtp.configuration.hostname = "test.mailu.io"
    //app.smtp.configuration.port = 25
    app.smtp.configuration.helloMethod = .ehlo
    app.smtp.configuration.secure = .startTlsWhenAvailable
//    app.smtp.configuration.
    app.smtp.configuration.username = "admin@test.mailu.io"
    app.smtp.configuration.password = "letmein"*/
//    app.jwt.signers.
    
    // register routes
    try routes(app)
}
