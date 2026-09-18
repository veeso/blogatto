# Build the project.
[group('build')]
build args="":
  gleam build {{ args }}

# Delete build artifacts for this project.
[group('build')]
[confirm("Are you sure you want to clean the build artifacts?")]
clean:
  gleam clean
