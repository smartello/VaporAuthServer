<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square" alt="MIT License" />
    </a>
    <a href="https://github.com/smartello/VaporAuthServer/actions">
        <img src="https://github.com/smartello/VaporAuthServer/workflows/Swift/badge.svg?style=flat-square" alt="Continuous Integration" />
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.3-brightgreen.svg?style=flat-square" alt="Swift 5.3" />
    </a>
    <a href="https://vapor.codes">
        <img src="https://img.shields.io/badge/vapor-4.0-blue.svg?style=flat-square" alt="Vapor 4" />
    </a>
    <span>
        <img src="https://img.shields.io/github/release/smartello/VaporAuthServer?style=flat-square" />
    </span>
    <span>
        <img src="https://img.shields.io/github/last-commit/smartello/VaporAuthServer?style=flat-square" />
    </span>
</p>

# VaporAuthServer
The intention of this work is to create a JWT based auth server API for [Vapor 4](https://vapor.codes) decoupled from database, email agent and etc.

The project is in the active development phase right now: tests don't pass (and barely present), there's more coupling than needed, some useless packages and it's a ready-to-use vapor app which is not a final goal. Ultimately, it must be a package that one will set as a dependency, map routes and start their own app. The server may then be a central authentication node for multiple projects (think of [Auth0](https://auth0.com)) or be incorporated into the app itself

Refer to the Projects page to figure out what is going on.
