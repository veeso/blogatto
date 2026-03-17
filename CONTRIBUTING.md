# Contributing to Blogatto

First off, thank you for considering contributing to Blogatto! Every contribution is appreciated, whether it's a bug report, a feature request, or a pull request.

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

## Reporting Issues

You can report bugs and request features on [GitHub Issues](https://github.com/veeso/blogatto/issues) or on [Codeberg](https://codeberg.org/veeso/blogatto/issues). Issues are typically tracked and resolved on GitHub.

When reporting a bug, please include:

- Gleam and OTP versions
- A minimal reproducible example
- Expected vs actual behavior

## Development Setup

### Prerequisites

- [Gleam](https://gleam.run) >= 1.15.0
- [Erlang/OTP](https://www.erlang.org) >= 28
- [Rebar3](https://rebar3.org)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/veeso/blogatto.git
cd blogatto

# Download dependencies
gleam deps download

# Run tests
gleam test

# Format code
gleam format src test
```

## Making Changes

### Branch Naming

Branch names must follow conventional commit prefixes, matching the type of change:

- `feat/short-description` — new features
- `fix/short-description` — bug fixes
- `refactor/short-description` — code refactoring
- `perf/short-description` — performance improvements
- `docs/short-description` — documentation changes
- `test/short-description` — test additions or fixes
- `ci/short-description` — CI/CD changes
- `chore/short-description` — maintenance tasks
- `build/short-description` — build system or dependency changes

### Commit Messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/). The changelog is generated with git-cliff, so following this format is mandatory.

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:** `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `ci`, `chore`, `build`

Examples:

```
feat: add support for custom post sorting
fix(feed): escape special characters in RSS titles
refactor!: rename MarkdownConfig fields for clarity
```

A `!` after the type/scope indicates a breaking change.

### Code Style

- Follow [Gleam official conventions](https://gleam.run/writing-gleam/)
- Use qualified imports only (except for types and constructors)
- `snake_case` for functions, `PascalCase` for types
- Singular module names
- Never use `let assert` or `panic` in library code — always return `Result`
- Module docs use `////` comments; public functions and types get `///` doc comments
- Internal modules go under `blogatto/internal/` and are not part of the public API

### Before Submitting

1. **Run the tests**: `gleam test`
2. **Format your code**: `gleam format src test`
3. **Check formatting**: `gleam format --check src test`

All three checks run in CI and must pass before a PR can be merged.

## Pull Requests

1. Fork the repository and create your branch from `main`
2. Make your changes following the guidelines above
3. Open a pull request targeting the `main` branch
4. Fill in a clear description of what you changed and why

A maintainer will review your PR. At least one maintainer approval is required before merging.

## License

By contributing to Blogatto, you agree that your contributions will be licensed under the [MIT License](LICENSE).
