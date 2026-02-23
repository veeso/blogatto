import blogatto/config
import blogatto/error
import blogatto/internal/builder/static as static_builder
import gleeunit/should
import simplifile
import temporary

fn minimal_config(output_dir: String) -> config.Config(msg) {
  config.new("https://example.com")
  |> config.output_dir(output_dir)
}

// --- No static dir configured ---

pub fn build_with_no_static_dir_returns_ok_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())

    let cfg = minimal_config(dir)

    static_builder.build(cfg)
    |> should.be_ok
  }
}

// --- Copying static files ---

pub fn build_copies_single_file_from_static_dir_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use src <- temporary.create(temporary.directory())

    let assert Ok(_) =
      simplifile.write(src <> "/style.css", "body { color: red; }")

    let cfg =
      minimal_config(dir)
      |> config.static_dir(src)

    static_builder.build(cfg)
    |> should.be_ok

    simplifile.is_file(dir <> "/style.css")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_preserves_file_content_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use src <- temporary.create(temporary.directory())

    let css_content = "body { margin: 0; padding: 0; }"
    let assert Ok(_) = simplifile.write(src <> "/main.css", css_content)

    let cfg =
      minimal_config(dir)
      |> config.static_dir(src)

    static_builder.build(cfg)
    |> should.be_ok

    simplifile.read(dir <> "/main.css")
    |> should.be_ok
    |> should.equal(css_content)
  }
}

pub fn build_copies_multiple_files_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use src <- temporary.create(temporary.directory())

    let assert Ok(_) = simplifile.write(src <> "/style.css", "css")
    let assert Ok(_) = simplifile.write(src <> "/app.js", "js")
    let assert Ok(_) = simplifile.write(src <> "/favicon.ico", "icon")

    let cfg =
      minimal_config(dir)
      |> config.static_dir(src)

    static_builder.build(cfg)
    |> should.be_ok

    simplifile.is_file(dir <> "/style.css")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(dir <> "/app.js")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(dir <> "/favicon.ico")
    |> should.be_ok
    |> should.be_true
  }
}

// --- Nested directory structure ---

pub fn build_preserves_nested_directory_structure_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use src <- temporary.create(temporary.directory())

    let assert Ok(_) = simplifile.create_directory_all(src <> "/css")
    let assert Ok(_) = simplifile.create_directory_all(src <> "/js")
    let assert Ok(_) = simplifile.write(src <> "/css/main.css", "css content")
    let assert Ok(_) = simplifile.write(src <> "/js/app.js", "js content")

    let cfg =
      minimal_config(dir)
      |> config.static_dir(src)

    static_builder.build(cfg)
    |> should.be_ok

    simplifile.is_directory(dir <> "/css")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(dir <> "/css/main.css")
    |> should.be_ok
    |> should.be_true

    simplifile.is_directory(dir <> "/js")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(dir <> "/js/app.js")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_preserves_deeply_nested_structure_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use src <- temporary.create(temporary.directory())

    let assert Ok(_) =
      simplifile.create_directory_all(src <> "/assets/images/icons")
    let assert Ok(_) =
      simplifile.write(src <> "/assets/images/icons/logo.svg", "<svg/>")

    let cfg =
      minimal_config(dir)
      |> config.static_dir(src)

    static_builder.build(cfg)
    |> should.be_ok

    simplifile.is_file(dir <> "/assets/images/icons/logo.svg")
    |> should.be_ok
    |> should.be_true

    simplifile.read(dir <> "/assets/images/icons/logo.svg")
    |> should.be_ok
    |> should.equal("<svg/>")
  }
}

// --- Empty static dir ---

pub fn build_with_empty_static_dir_succeeds_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use src <- temporary.create(temporary.directory())

    let cfg =
      minimal_config(dir)
      |> config.static_dir(src)

    static_builder.build(cfg)
    |> should.be_ok
  }
}

// --- Error handling ---

pub fn build_returns_error_for_nonexistent_static_dir_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())

    let cfg =
      minimal_config(dir)
      |> config.static_dir("./nonexistent_static_dir_test")

    let result = static_builder.build(cfg)

    result
    |> should.be_error

    let assert Error(error.File(_)) = result
    Nil
  }
}
