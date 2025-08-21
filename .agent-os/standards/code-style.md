# Code Style Guide

## Context

Code style rules for iOS Swift development following Apple's Swift API Design Guidelines.

<conditional-block context-check="swift-formatting">
IF this Swift Formatting section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using Swift Formatting rules already in context"
ELSE:
  READ: The following Swift formatting rules

## Swift Formatting

### Indentation
- Use 4 spaces for indentation (never tabs)
- Maintain consistent indentation throughout files
- Align chained method calls and closure parameters
- Use continuation indentation for wrapped lines

### Naming Conventions
- **Variables and Methods**: Use camelCase (e.g., `userProfile`, `calculateTotal`)
- **Classes, Structs, Enums, Protocols**: Use PascalCase (e.g., `UserProfile`, `PaymentProcessor`)
- **Constants**: Use camelCase for local constants, PascalCase for global/static (e.g., `maxRetryCount`, `APIConstants.BaseURL`)
- **Enum cases**: Use camelCase (e.g., `.loading`, `.success`, `.networkError`)
- **File names**: Use PascalCase matching the main type (e.g., `UserProfileView.swift`)

### String Formatting
- Use double quotes for strings: `"Hello World"`
- Use string interpolation: `"Hello \(userName)"`
- Use multi-line string literals for long strings
- Prefer string interpolation over concatenation

### Code Comments
- Use `//` for single-line comments
- Use `/* */` for multi-line comments
- Use `/// ` for documentation comments (Swift DocC format)
- Add brief comments above non-obvious business logic
- Document complex algorithms or calculations
- Explain the "why" behind implementation choices
- Use `// MARK: -` for section organization
- Never remove existing comments unless removing the associated code
- Update comments when modifying code to maintain accuracy
- Keep comments concise and relevant

### Swift-Specific Guidelines
- Use `let` for immutable values, `var` for mutable
- Prefer explicit types for clarity when type inference is ambiguous
- Use trailing closure syntax when possible
- Prefer `guard` statements for early returns
- Use `@MainActor` for UI-related classes and methods
- Organize code with `// MARK: -` sections
- Use SwiftUI property wrappers appropriately (`@State`, `@StateObject`, `@Published`)
</conditional-block>

<conditional-block task-condition="swift-ios" context-check="swift-ios-style">
IF current task involves writing or updating Swift/iOS code:
  IF swift-ios-style already in context:
    SKIP: Re-reading this section
    NOTE: "Using Swift/iOS style guide already in context"
  ELSE:
    READ: @.agent-os/standards/code-style/swift-style.md for detailed Swift formatting
    READ: The following Swift/iOS specific guidelines

### iOS Swift Best Practices

#### Architecture Patterns
- Use MVVM pattern with SwiftUI
- Implement Coordinator pattern for navigation
- Use Protocol-Oriented Programming for dependency injection
- Apply Clean Architecture principles (UI → Business Logic → Data Layer)

#### SwiftUI Guidelines
- Use `@State` for local view state
- Use `@StateObject` for creating observed objects
- Use `@ObservedObject` for passed-in observed objects
- Use `@Published` for observable properties
- Use `@EnvironmentObject` for app-wide state
- Use `@MainActor` for UI-related classes

#### Concurrency
- Prefer `async/await` over completion handlers
- Use `@MainActor` for UI updates
- Use `Task` for structured concurrency
- Implement proper error handling with `do/catch`

#### Security & Performance
- Store API keys securely (never hardcode)
- Implement certificate pinning for network security
- Use rate limiting for API calls
- Implement multi-layer caching strategies
- Use lazy loading for services

#### Testing
- Write UI tests using XCUITest
- Use Page Object pattern for maintainable tests
- Create mock services for isolated testing
- Add accessibility IDs for test identification

#### Code Organization
- Group related functionality with `// MARK: -`
- Use extensions for protocol conformance
- Separate services into dedicated files
- Follow single responsibility principle
ELSE:
  SKIP: Swift/iOS guidelines not relevant to current task
</conditional-block>

<conditional-block task-condition="html-css-tailwind" context-check="html-css-style">
IF current task involves writing or updating HTML, CSS, or TailwindCSS:
  SKIP: HTML/CSS style guides not applicable to iOS Swift project
</conditional-block>

<conditional-block task-condition="javascript" context-check="javascript-style">
IF current task involves writing or updating JavaScript:
  SKIP: JavaScript style guide not applicable to iOS Swift project
</conditional-block>
