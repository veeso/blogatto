import blogatto/config/markdown.{Center, Left, Right}
import gleam/option.{None, Some}
import gleeunit/should
import lustre/attribute
import lustre/element
import lustre/element/html

// --- default / default_components ---

pub fn default_has_empty_paths_test() {
  let cfg = markdown.default()
  cfg.paths
  |> should.equal([])
}

pub fn default_has_no_template_test() {
  let cfg = markdown.default()
  cfg.template
  |> should.equal(None)
}

pub fn default_has_no_route_builder_test() {
  let cfg = markdown.default()
  cfg.route_builder
  |> should.equal(None)
}

pub fn default_has_no_route_prefix_test() {
  let cfg = markdown.default()
  cfg.route_prefix
  |> should.equal(None)
}

pub fn default_options_test() {
  let cfg = markdown.default()
  cfg.options
  |> should.equal(markdown.default_options())

  cfg.options.autolinks
  |> should.equal(True)

  cfg.options.footnotes
  |> should.equal(True)

  cfg.options.emojis_shortcodes
  |> should.equal(True)

  cfg.options.heading_ids
  |> should.equal(False)

  cfg.options.tables
  |> should.equal(True)

  cfg.options.tasklists
  |> should.equal(True)
}

pub fn default_components_renders_paragraph_test() {
  let comps = markdown.default_components()
  let result = comps.p([html.text("hello")])
  result
  |> element.to_string
  |> should.equal("<p>hello</p>")
}

pub fn default_components_renders_h1_test() {
  let comps = markdown.default_components()
  let result = comps.h1("title", [html.text("Title")])
  result
  |> element.to_string
  |> should.equal("<h1 id=\"title\">Title</h1>")
}

// --- excerpt_len ---

pub fn excerpt_len_overrides_default_test() {
  let cfg =
    markdown.default()
    |> markdown.excerpt_len(100)

  cfg.excerpt_len
  |> should.equal(100)
}

// --- template ---

pub fn template_overrides_default_test() {
  let tmpl = fn(_post, _all_posts) { html.div([], [html.text("custom")]) }
  let cfg =
    markdown.default()
    |> markdown.template(tmpl)

  cfg.template
  |> should.be_some
}

// --- options ---

pub fn options_overrides_defaults_test() {
  let custom_options =
    markdown.Options(
      autolinks: False,
      footnotes: False,
      emojis_shortcodes: False,
      heading_ids: True,
      tables: False,
      tasklists: False,
    )

  let cfg =
    markdown.default()
    |> markdown.options(custom_options)

  cfg.options
  |> should.equal(custom_options)
}

//  --- route_prefix ---

pub fn route_prefix_adds_prefix_to_url_test() {
  let cfg =
    markdown.default()
    |> markdown.route_prefix("blog")

  cfg.route_prefix
  |> should.equal(Some("blog"))
}

// --- route_builder ---

pub fn route_builder_overrides_default_url_test() {
  let builder = fn(_metadata) { "/custom-url/" }
  let cfg =
    markdown.default()
    |> markdown.route_builder(builder)

  cfg.route_builder
  |> should.equal(Some(builder))
}

// --- markdown_path ---

pub fn markdown_path_adds_path_test() {
  let cfg =
    markdown.default()
    |> markdown.markdown_path("./blog")

  cfg.paths
  |> should.equal(["./blog"])
}

pub fn markdown_path_prepends_multiple_paths_test() {
  let cfg =
    markdown.default()
    |> markdown.markdown_path("./blog")
    |> markdown.markdown_path("./articles")

  // ./articles was prepended last, so it comes first
  cfg.paths
  |> should.equal(["./articles", "./blog"])
}

// --- template ---

pub fn template_sets_template_function_test() {
  let tmpl = fn(_post, _all_posts) { html.div([], [html.text("custom")]) }
  let cfg =
    markdown.default()
    |> markdown.template(tmpl)

  cfg.template
  |> should.be_some
}

// --- components setter ---

pub fn components_replaces_all_components_test() {
  let custom_comps = markdown.default_components()
  let cfg =
    markdown.default()
    |> markdown.components(custom_comps)

  // Verify components were set by testing a render
  let result = cfg.components.p([html.text("test")])
  result
  |> element.to_string
  |> should.equal("<p>test</p>")
}

// --- Individual component setters ---

pub fn a_setter_replaces_link_component_test() {
  let custom_a = fn(href, _title, children) {
    html.a(
      [attribute.attribute("href", href), attribute.class("link")],
      children,
    )
  }
  let cfg =
    markdown.default()
    |> markdown.a(custom_a)

  cfg.components.a("https://example.com", None, [html.text("click")])
  |> element.to_string
  |> should.equal("<a class=\"link\" href=\"https://example.com\">click</a>")
}

pub fn blockquote_setter_replaces_component_test() {
  let custom = fn(children) {
    html.blockquote([attribute.class("quote")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.blockquote(custom)

  cfg.components.blockquote([html.text("quoted")])
  |> element.to_string
  |> should.equal("<blockquote class=\"quote\">quoted</blockquote>")
}

pub fn checkbox_setter_replaces_component_test() {
  let custom = fn(checked) {
    case checked {
      True -> html.text("[x]")
      False -> html.text("[ ]")
    }
  }
  let cfg =
    markdown.default()
    |> markdown.checkbox(custom)

  cfg.components.checkbox(True)
  |> element.to_string
  |> should.equal("[x]")
}

pub fn code_setter_replaces_component_test() {
  let custom = fn(_lang, children) {
    html.code([attribute.class("highlight")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.code(custom)

  cfg.components.code(Some("gleam"), [html.text("let x = 1")])
  |> element.to_string
  |> should.equal("<code class=\"highlight\">let x = 1</code>")
}

pub fn del_setter_replaces_component_test() {
  let custom = fn(children) { html.s([], children) }
  let cfg =
    markdown.default()
    |> markdown.del(custom)

  cfg.components.del([html.text("removed")])
  |> element.to_string
  |> should.equal("<s>removed</s>")
}

pub fn em_setter_replaces_component_test() {
  let custom = fn(children) { html.em([attribute.class("italic")], children) }
  let cfg =
    markdown.default()
    |> markdown.em(custom)

  cfg.components.em([html.text("emphasis")])
  |> element.to_string
  |> should.equal("<em class=\"italic\">emphasis</em>")
}

pub fn footnote_setter_replaces_component_test() {
  let custom = fn(n, children) {
    html.sup([], [html.text("[" <> int_to_string(n) <> "]"), ..children])
  }
  let cfg =
    markdown.default()
    |> markdown.footnote(custom)

  cfg.components.footnote(1, [])
  |> element.to_string
  |> should.equal("<sup>[1]</sup>")
}

pub fn h1_setter_replaces_component_test() {
  let custom = fn(id, children) {
    html.h1([attribute.id(id), attribute.class("heading")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.h1(custom)

  cfg.components.h1("intro", [html.text("Intro")])
  |> element.to_string
  |> should.equal("<h1 class=\"heading\" id=\"intro\">Intro</h1>")
}

pub fn h2_setter_replaces_component_test() {
  let custom = fn(id, children) {
    html.h2([attribute.id(id), attribute.class("h2")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.h2(custom)

  cfg.components.h2("section", [html.text("Section")])
  |> element.to_string
  |> should.equal("<h2 class=\"h2\" id=\"section\">Section</h2>")
}

pub fn h3_setter_replaces_component_test() {
  let custom = fn(id, children) {
    html.h3([attribute.id(id), attribute.class("h3")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.h3(custom)

  cfg.components.h3("sub", [html.text("Sub")])
  |> element.to_string
  |> should.equal("<h3 class=\"h3\" id=\"sub\">Sub</h3>")
}

pub fn h4_setter_replaces_component_test() {
  let custom = fn(id, children) {
    html.h4([attribute.id(id), attribute.class("h4")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.h4(custom)

  cfg.components.h4("sub2", [html.text("Sub2")])
  |> element.to_string
  |> should.equal("<h4 class=\"h4\" id=\"sub2\">Sub2</h4>")
}

pub fn h5_setter_replaces_component_test() {
  let custom = fn(id, children) {
    html.h5([attribute.id(id), attribute.class("h5")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.h5(custom)

  cfg.components.h5("sub3", [html.text("Sub3")])
  |> element.to_string
  |> should.equal("<h5 class=\"h5\" id=\"sub3\">Sub3</h5>")
}

pub fn h6_setter_replaces_component_test() {
  let custom = fn(id, children) {
    html.h6([attribute.id(id), attribute.class("h6")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.h6(custom)

  cfg.components.h6("sub4", [html.text("Sub4")])
  |> element.to_string
  |> should.equal("<h6 class=\"h6\" id=\"sub4\">Sub4</h6>")
}

pub fn hr_setter_replaces_component_test() {
  let custom = fn() { html.div([attribute.class("separator")], []) }
  let cfg =
    markdown.default()
    |> markdown.hr(custom)

  cfg.components.hr()
  |> element.to_string
  |> should.equal("<div class=\"separator\"></div>")
}

pub fn img_setter_replaces_component_test() {
  let custom = fn(src, alt, _title) {
    html.img([
      attribute.src(src),
      attribute.alt(alt),
      attribute.class("image"),
    ])
  }
  let cfg =
    markdown.default()
    |> markdown.img(custom)

  cfg.components.img("/photo.jpg", "A photo", None)
  |> element.to_string
  |> should.equal("<img alt=\"A photo\" class=\"image\" src=\"/photo.jpg\">")
}

pub fn li_setter_replaces_component_test() {
  let custom = fn(children) { html.li([attribute.class("item")], children) }
  let cfg =
    markdown.default()
    |> markdown.li(custom)

  cfg.components.li([html.text("item")])
  |> element.to_string
  |> should.equal("<li class=\"item\">item</li>")
}

pub fn mark_setter_replaces_component_test() {
  let custom = fn(children) {
    html.mark([attribute.class("highlight")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.mark(custom)

  cfg.components.mark([html.text("marked")])
  |> element.to_string
  |> should.equal("<mark class=\"highlight\">marked</mark>")
}

pub fn ol_setter_replaces_component_test() {
  let custom = fn(_start, children) {
    html.ol([attribute.class("ordered")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.ol(custom)

  cfg.components.ol(Some(1), [html.li([], [html.text("first")])])
  |> element.to_string
  |> should.equal("<ol class=\"ordered\"><li>first</li></ol>")
}

pub fn p_setter_replaces_component_test() {
  let custom = fn(children) { html.p([attribute.class("paragraph")], children) }
  let cfg =
    markdown.default()
    |> markdown.p(custom)

  cfg.components.p([html.text("text")])
  |> element.to_string
  |> should.equal("<p class=\"paragraph\">text</p>")
}

pub fn pre_setter_replaces_component_test() {
  let custom = fn(children) {
    html.pre([attribute.class("code-block")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.pre(custom)

  cfg.components.pre([html.text("code")])
  |> element.to_string
  |> should.equal("<pre class=\"code-block\">code</pre>")
}

pub fn strong_setter_replaces_component_test() {
  let custom = fn(children) { html.strong([attribute.class("bold")], children) }
  let cfg =
    markdown.default()
    |> markdown.strong(custom)

  cfg.components.strong([html.text("bold")])
  |> element.to_string
  |> should.equal("<strong class=\"bold\">bold</strong>")
}

pub fn table_setter_replaces_component_test() {
  let custom = fn(children) { html.table([attribute.class("tbl")], children) }
  let cfg =
    markdown.default()
    |> markdown.table(custom)

  cfg.components.table([])
  |> element.to_string
  |> should.equal("<table class=\"tbl\"></table>")
}

pub fn tbody_setter_replaces_component_test() {
  let custom = fn(children) { html.tbody([attribute.class("body")], children) }
  let cfg =
    markdown.default()
    |> markdown.tbody(custom)

  cfg.components.tbody([])
  |> element.to_string
  |> should.equal("<tbody class=\"body\"></tbody>")
}

pub fn td_setter_replaces_component_test() {
  let custom = fn(_alignment, children) {
    html.td([attribute.class("cell")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.td(custom)

  cfg.components.td(Left, [html.text("data")])
  |> element.to_string
  |> should.equal("<td class=\"cell\">data</td>")
}

pub fn th_setter_replaces_component_test() {
  let custom = fn(_alignment, children) {
    html.th([attribute.class("header")], children)
  }
  let cfg =
    markdown.default()
    |> markdown.th(custom)

  cfg.components.th(Left, [html.text("col")])
  |> element.to_string
  |> should.equal("<th class=\"header\">col</th>")
}

pub fn thead_setter_replaces_component_test() {
  let custom = fn(children) { html.thead([attribute.class("head")], children) }
  let cfg =
    markdown.default()
    |> markdown.thead(custom)

  cfg.components.thead([])
  |> element.to_string
  |> should.equal("<thead class=\"head\"></thead>")
}

pub fn tr_setter_replaces_component_test() {
  let custom = fn(children) { html.tr([attribute.class("row")], children) }
  let cfg =
    markdown.default()
    |> markdown.tr(custom)

  cfg.components.tr([])
  |> element.to_string
  |> should.equal("<tr class=\"row\"></tr>")
}

pub fn ul_setter_replaces_component_test() {
  let custom = fn(children) { html.ul([attribute.class("list")], children) }
  let cfg =
    markdown.default()
    |> markdown.ul(custom)

  cfg.components.ul([html.li([], [html.text("item")])])
  |> element.to_string
  |> should.equal("<ul class=\"list\"><li>item</li></ul>")
}

// --- Alignment variants in td/th ---

pub fn td_setter_with_center_alignment_test() {
  let custom = fn(alignment, children) {
    case alignment {
      Center -> html.td([attribute.class("center")], children)
      _ -> html.td([], children)
    }
  }
  let cfg =
    markdown.default()
    |> markdown.td(custom)

  cfg.components.td(Center, [html.text("data")])
  |> element.to_string
  |> should.equal("<td class=\"center\">data</td>")
}

pub fn td_setter_with_right_alignment_test() {
  let custom = fn(alignment, children) {
    case alignment {
      Right -> html.td([attribute.class("right")], children)
      _ -> html.td([], children)
    }
  }
  let cfg =
    markdown.default()
    |> markdown.td(custom)

  cfg.components.td(Right, [html.text("data")])
  |> element.to_string
  |> should.equal("<td class=\"right\">data</td>")
}

pub fn th_setter_with_center_alignment_test() {
  let custom = fn(alignment, children) {
    case alignment {
      Center -> html.th([attribute.class("center")], children)
      _ -> html.th([], children)
    }
  }
  let cfg =
    markdown.default()
    |> markdown.th(custom)

  cfg.components.th(Center, [html.text("col")])
  |> element.to_string
  |> should.equal("<th class=\"center\">col</th>")
}

pub fn th_setter_with_right_alignment_test() {
  let custom = fn(alignment, children) {
    case alignment {
      Right -> html.th([attribute.class("right")], children)
      _ -> html.th([], children)
    }
  }
  let cfg =
    markdown.default()
    |> markdown.th(custom)

  cfg.components.th(Right, [html.text("col")])
  |> element.to_string
  |> should.equal("<th class=\"right\">col</th>")
}

// --- Component setter chaining ---

pub fn multiple_component_setters_compose_test() {
  let cfg =
    markdown.default()
    |> markdown.p(fn(children) {
      html.p([attribute.class("custom-p")], children)
    })
    |> markdown.strong(fn(children) {
      html.strong([attribute.class("custom-bold")], children)
    })
    |> markdown.h1(fn(id, children) {
      html.h1([attribute.id(id), attribute.class("custom-h1")], children)
    })

  cfg.components.p([html.text("text")])
  |> element.to_string
  |> should.equal("<p class=\"custom-p\">text</p>")

  cfg.components.strong([html.text("bold")])
  |> element.to_string
  |> should.equal("<strong class=\"custom-bold\">bold</strong>")

  cfg.components.h1("title", [html.text("Title")])
  |> element.to_string
  |> should.equal("<h1 class=\"custom-h1\" id=\"title\">Title</h1>")
}

// --- Helper ---

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    _ -> "N"
  }
}
