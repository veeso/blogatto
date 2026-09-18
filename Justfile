import "./just/build.just"
import "./just/changelog.just"
import "./just/code_check.just"
import "./just/publish.just"
import "./just/test.just"

# List every available command.
default:
    @just --list
