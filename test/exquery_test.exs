defmodule ExqueryTest do
  use ExUnit.Case
  alias Exquery, as: E
  

  def foo(<<head::binary-size(1), rest::binary>>) when head == "f" do
    :ok
  end
  def foo(o) do
    o
  end

  test "foo" do
    IO.inspect foo("foo")
  end


  test "can tokenize basic html" do
    assert E.tokenize("<div>hello >   </div>") ==
    [
      {:open_tag, "div", []},
      {:text, "hello >   ", []},
      {:close_tag, "div", []}
    ]

    assert E.tokenize(String.strip("""
      <div>hello <italic>world</italic></div>
    """)) == [
      {:open_tag, "div", []},
        {:text, "hello ", []},
        {:open_tag, "italic", []},
          {:text, "world", []},
        {:close_tag, "italic", []},
      {:close_tag, "div", []}
    ]

    assert E.tokenize(String.strip("""
      <div> h e l l o
        <ul>
          <li>foo</li>
          <li>bar</li>
        </ul>
      </div>
    """)) == [
      {:open_tag, "div", []}, 
        {:text, " h e l l o\n    ", []}, 
          {:open_tag, "ul", []},
            {:open_tag, "li", []}, 
              {:text, "foo", []}, 
            {:close_tag, "li", []},
            {:open_tag, "li", []}, 
              {:text, "bar", []}, 
            {:close_tag, "li", []},
          {:close_tag, "ul", []}, 
        {:close_tag, "div", []}
      ]
  end

  test "can parse a comment" do
    assert E.tokenize(String.strip("""
      <div>
        <!-- i am a comment -->
      </div>
    """)) == [
      {:open_tag, "div", []},
        {:comment, " i am a comment ", []},
      {:close_tag, "div", []}
    ]
  end

  test "can parse an attribute string" do
    assert E.to_attributes("class='hel\"lo'", []) == {
      "", 
      [{"class", "hel\"lo"}]
    }

    assert E.to_attributes(
      "class='hello world' id=\"foo-bar\"", 
      []
    ) == {
      "",
      [
        {"id", "foo-bar"},
        {"class", "hello world"}
      ]
    }

    assert E.to_attributes("class=foo id=bar something=else", []) == {
      "",
      [
        {"something", "else"},
        {"id", "bar"},
        {"class", "foo"}
      ]
    }

    assert E.to_attributes("class=\"foo\"id='bar' something='else>", []) == {
      ">",
      [
        {"something", "else"},
        {"id", "bar"},
        {"class", "foo"}
      ]
    }

    assert E.to_attributes(
      " 
      selected 
      checked", 
      []
    ) == {
      "",
      [
        {"checked", ""},
        {"selected", ""},
        # {"class", "hello world"}
      ]
    }

    assert E.to_attributes(
      "class='hello world' selected checked", 
      []
    ) == {
      "",
      [
        {"checked", ""},
        {"selected", ""},
        {"class", "hello world"}
      ]
    }
  end

  test "can parse attributes" do
    assert E.tokenize(String.strip("""
      <a href='google dot com'>hello</a>
    """)) === [
      {:open_tag, "a", [{"href", "google dot com"}]},
        {:text, "hello", []},
      {:close_tag, "a", []}
    ]
  end

  test "can parse a doctype" do
    assert E.tokenize(String.strip("""
      <!DOCTYPE html>
      <html>
        <body>
        </body>
      </html>
    """)) == [
      {:doctype, "DOCTYPE", [{"html", ""}]},
      {:open_tag, "html", []},
        {:open_tag, "body", []},
        {:close_tag, "body", []},
      {:close_tag, "html", []}
    ]

    assert E.tokenize(String.strip("""
      <!DOCTYPE

      html
      >
      <html>
        <body>
        </body>
      </html>
    """)) == [
      {:doctype, "DOCTYPE", [{"html", ""}]},
      {:open_tag, "html", []},
        {:open_tag, "body", []},
        {:close_tag, "body", []},
      {:close_tag, "html", []}
    ]
  end


end
