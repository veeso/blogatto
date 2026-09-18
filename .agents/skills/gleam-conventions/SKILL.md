---
name: gleam-conventions
description: ALWAYS use this skill BEFORE writing or modifying ANY Gleam code (.gleam files), even for simple Hello World programs. Enforces idiomatic Gleam coding guidelines from the official Gleam conventions (conventions, patterns, and anti-patterns). This skill is MANDATORY for all Gleam development.
license: MIT
metadata:
  author: veeso
  version: "1.0.0"
  tags:
    - gleam
    - conventions
    - linting
---

# Gleam Development

This skill automatically enforces Gleam coding standards and best practices when creating or modifying Gleam code.

## Instructions

**CRITICAL**: This skill MUST be invoked for ANY Gleam code operation, including:

- Creating new .gleam files (even simple examples like Hello World)
- Modifying existing .gleam files (any change, no matter how small)
- Reviewing Gleam code
- Refactoring Gleam code

**Process**:

1. Read the [conventions-patterns-anti-patterns.djot](./conventions-patterns-anti-patterns.djot) file to understand all compliance requirements
2. Before writing/modifying ANY Gleam code, ensure edits are conformant to the guidelines
3. Apply the rules according to their tier (see below)
4. Comments must ALWAYS be written in American English, unless the user explicitly requests a different language.

**No exceptions**: Even for trivial code like "Hello World", guidelines must be followed.

## How to interpret the djot file

The file uses [djot](https://djot.net/) markup format. It is structured into three top-level sections, each representing a tier of rules:

### Conventions (Mandatory)

Rules under the `## Conventions` heading are **mandatory** and must be adhered to always. These are non-negotiable requirements for all Gleam code.

### Patterns (Recommended)

Rules under the `## Patterns` heading are **recommended** approaches. Apply them whenever you think they would benefit the code. They represent idiomatic solutions to common problems.

### Anti-patterns (Avoid)

Rules under the `## Anti-patterns` heading describe practices that should be **avoided**. Never introduce these patterns into code.

### Reading the format

- Each rule is a `###` subsection within its tier
- Code examples use `` ```gleam `` fenced blocks with `// Good` and `// Bad` comments to show correct vs incorrect usage
- Prose paragraphs explain the rationale and nuances of each rule
- Some rules reference external talks or resources for deeper understanding

---
