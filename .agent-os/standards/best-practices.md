# Development Best Practices

## Context

iOS Swift development guidelines for Smart City Guide project.

<conditional-block context-check="core-principles">
IF this Core Principles section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using Core Principles already in context"
ELSE:
  READ: The following principles

## Core Principles

### Keep It Simple
- Implement code in the fewest lines possible
- Avoid over-engineering solutions
- Choose straightforward approaches over clever ones

### Optimize for Readability
- Prioritize code clarity over micro-optimizations
- Write self-documenting code with clear variable names
- Add comments for "why" not "what"

### DRY (Don't Repeat Yourself)
- Extract repeated business logic to private methods
- Extract repeated UI markup to reusable components
- Create utility functions for common operations

### File Structure
- Keep files focused on a single responsibility
- Group related functionality together
- Use consistent naming conventions
- Follow iOS project structure (Models, Views, Services, Utilities)
</conditional-block>

<conditional-block context-check="ios-specific-practices">
IF this iOS Specific Practices section already read in current context:
  SKIP: Re-reading this section
  NOTE: "Using iOS Specific Practices already in context"
ELSE:
  READ: The following iOS guidelines

## iOS Specific Practices

### Memory Management
- Use weak references to prevent retain cycles
- Implement proper lifecycle management in views
- Use @StateObject for object creation, @ObservedObject for injection

### Performance
- Use lazy loading for expensive operations
- Implement proper caching strategies
- Avoid blocking the main thread with heavy computations

### Security
- Never hardcode API keys or sensitive data
- Use secure storage for user data
- Implement certificate pinning for network requests
- Validate all user inputs

### User Experience
- Provide loading states for async operations
- Handle errors gracefully with user-friendly messages
- Implement proper accessibility support
- Use haptic feedback appropriately
</conditional-block>

<conditional-block context-check="dependencies" task-condition="choosing-external-library">
IF current task involves choosing an external library:
  IF Dependencies section already read in current context:
    SKIP: Re-reading this section
    NOTE: "Using Dependencies guidelines already in context"
  ELSE:
    READ: The following guidelines
ELSE:
  SKIP: Dependencies section not relevant to current task

## Dependencies

### iOS Library Selection
When adding iOS dependencies:
- Prefer Apple's native frameworks (MapKit, CoreLocation, Foundation)
- For third-party libraries, check:
  - iOS compatibility and Swift version support
  - Recent commits (within last 6 months)
  - Active issue resolution and community support
  - Number of stars/downloads on GitHub
  - Clear documentation and examples
  - App Store compliance and review guidelines compatibility
</conditional-block>
