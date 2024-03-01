require "../spec_helper"

describe Slang::Lexer do
  describe "html tags" do
    string = %[div\n  p text]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      it "is a div element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
      end
    end

    describe "second line, first token" do
      it "is a p element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("p")
        token.column_number.should eq(3)
        token.line_number.should eq(2)
        token.text_block.should be_false
        token.raw_text.should be_false
      end
    end

    describe "second line, second token" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["text"])
        token.column_number.should eq(5)
        token.line_number.should eq(2)
        token.text_block.should be_false
        token.raw_text.should be_false
      end
    end
  end

  describe "html tags with attributes" do
    string = %[div class="foo" id=bar]
    lexer = Slang::Lexer.new(string)

    describe "first line, first token" do
      it "is a div element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end

    describe "first line, second token" do
      it "is a class attribute" do
        token = lexer.next_token

        token.type.should eq(:ATTRIBUTE)
        token.name.should eq("class")
        token.value.should eq(%["foo"])
        token.column_number.should eq(5)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_true
      end
    end

    describe "first line, third token" do
      it "is an id attribute" do
        token = lexer.next_token

        token.type.should eq(:ATTRIBUTE)
        token.name.should eq("id")
        token.value.should eq(%[bar])
        token.column_number.should eq(17)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_true
      end
    end
  end

  describe "html tags with wrappers" do
    string = %[div(class="foo" id=bar)]
    lexer = Slang::Lexer.new(string)

    describe "first line, first token" do
      it "is a div element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end

    describe "first line, second token" do
      it "is a class attribute" do
        token = lexer.next_token

        token.type.should eq(:ATTRIBUTE)
        token.name.should eq("class")
        token.value.should eq(%["foo"])
        token.column_number.should eq(5)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_true
      end
    end

    describe "first line, third token" do
      it "is an id attribute" do
        token = lexer.next_token

        token.type.should eq(:ATTRIBUTE)
        token.name.should eq("id")
        token.value.should eq(%[bar])
        token.column_number.should eq(17)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_true
      end
    end
  end

  describe "html tags with shortcuts" do
    string =  %[div#foo.bar]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      token = lexer.next_token

      it "is a div element" do
        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end

      it "has an id attribute" do
        token.attributes["id"].should eq("\"foo\"")
      end

      it "has a class attribute" do
        token.attributes["class"].should eq(Set{"\"bar\""})
      end
    end
  end

  describe "html tags with text" do
    string = %[div #foo .bar]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      it "is a div element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end

    describe "first line, second token" do
      it "is text" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["#foo .bar"])
        token.column_number.should eq(5)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end
  end

  describe "html tags with interpolation" do
    string = %[div foo \#{bar} baz]
    lexer = Slang::Lexer.new(string)

    describe "first line, first token" do
      it "is a div element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
        token.inline.should be_false
      end
    end

    describe "first line, second token" do
      it "is text" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["foo "])
        token.column_number.should eq(5)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
        token.inline.should be_true
      end
    end

    describe "first line, third token" do
      it "is text" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq("bar")
        token.column_number.should eq(9)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_true
        token.inline.should be_true
      end
    end

    describe "first line, fourth token" do
      it "is text" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%[" baz"])
        token.column_number.should eq(15)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
        token.inline.should be_true
      end
    end
  end

  describe "html attributes with interpolation" do
    string = %[div title="\#{foo}" bar]
    lexer = Slang::Lexer.new(string)

    describe "first line, first token" do
      it "is a div element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end

    describe "first line, second token" do
      it "is a title attribute" do
        token = lexer.next_token

        token.type.should eq(:ATTRIBUTE)
        token.name.should eq("title")
        token.value.should eq(%["\#{foo}"])
        token.column_number.should eq(5)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_true
      end
    end

    describe "first line, third token" do
      it "is text" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["bar"])
        token.column_number.should eq(20)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end
  end

  describe "shortcuts with implicit tags" do
    string = %[#foo.bar]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      token = lexer.next_token

      it "is a div element" do
        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end

      it "has an id attribute" do
        token.attributes["id"].should eq("\"foo\"")
      end

      it "has a class attribute" do
        token.attributes["class"].should eq(Set{"\"bar\""})
      end
    end
  end

  describe "javascript blocks" do
    string = %[javascript:\n  if (x) {\n    x;\n  }]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      it "is a script element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("script")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end

    describe "second line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["if (x) {"])
        token.column_number.should eq(3)
        token.line_number.should eq(2)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end

    describe "third line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["x;"])
        token.column_number.should eq(5)
        token.line_number.should eq(3)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end

    describe "fourth line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["}"])
        token.column_number.should eq(3)
        token.line_number.should eq(4)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end
  end

  describe "css blocks" do
    string = %[css:\n  p {\n    display: none;\n  }]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      it "is a style element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("style")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end

    describe "second line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["p {"])
        token.column_number.should eq(3)
        token.line_number.should eq(2)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end

    describe "third line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["display: none;"])
        token.column_number.should eq(5)
        token.line_number.should eq(3)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end

    describe "fourth line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["}"])
        token.column_number.should eq(3)
        token.line_number.should eq(4)
        token.text_block.should be_false
        token.raw_text.should be_true
      end
    end
  end

  describe "text blocks" do
    context "with a pipe" do
      string = %[| First line.\n  Second line.]
      lexer = Slang::Lexer.new(string)

      describe "first line" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%["First line."])
          token.column_number.should eq(1)
          token.line_number.should eq(1)
          token.append_whitespace.should be_false
          token.text_block.should be_true
          token.raw_text.should be_true
        end
      end

      describe "second line" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%["Second line."])
          token.column_number.should eq(3)
          token.line_number.should eq(2)
          token.append_whitespace.should be_false
          token.text_block.should be_false
          token.raw_text.should be_true
        end
      end
    end

    context "with a quote" do
      string = %[' First line.\n  Second line.]
      lexer = Slang::Lexer.new(string)

      describe "first line" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%["First line."])
          token.column_number.should eq(1)
          token.line_number.should eq(1)
          token.append_whitespace.should be_true
          token.text_block.should be_true
          token.raw_text.should be_true
        end
      end

      describe "second line" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%["Second line."])
          token.column_number.should eq(3)
          token.line_number.should eq(2)
          token.append_whitespace.should be_false
          token.text_block.should be_false
          token.raw_text.should be_true
        end
      end
    end

    context "with interpolation" do
      string = %[| foo \#{bar} baz]
      lexer = Slang::Lexer.new(string)

      describe "first line, first token" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%["foo "])
          token.column_number.should eq(1)
          token.line_number.should eq(1)
          token.text_block.should be_true
          token.raw_text.should be_true
          token.escaped.should be_false
          token.inline.should be_false
        end
      end

      describe "first line, second token" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq("bar")
          token.column_number.should eq(7)
          token.line_number.should eq(1)
          token.text_block.should be_false
          token.raw_text.should be_true
          token.escaped.should be_true
          token.inline.should be_true
        end
      end

      describe "first line, third token" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%[" baz"])
          token.column_number.should eq(13)
          token.line_number.should eq(1)
          token.text_block.should be_false
          token.raw_text.should be_true
          token.escaped.should be_false
          token.inline.should be_true
        end
      end
    end

    context "with interpolation" do
      string = %q[| #{%{"hello #{"world"}"}}]
      lexer = Slang::Lexer.new(string)

      describe "first line, first token" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%[""])
          token.column_number.should eq(1)
          token.line_number.should eq(1)
          token.text_block.should be_true
          token.raw_text.should be_true
          token.escaped.should be_false
          token.inline.should be_false
        end
      end

      describe "first line, second token" do
        it "is a text element" do
          token = lexer.next_token

          token.type.should eq(:TEXT)
          token.value.should eq(%q[%{"hello #{"world"}"}])
          token.column_number.should eq(3)
          token.line_number.should eq(1)
          token.text_block.should be_false
          token.raw_text.should be_true
          token.escaped.should be_true
          token.inline.should be_true
        end
      end
    end
  end

  describe "code blocks" do
    string = %[crystal:\n  def foo\n    "\#{bar}"\n    "baz"\n  end]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      it "is a code element" do
        token = lexer.next_token

        token.type.should eq(:CODE)
        token.value.should be_nil
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_true
        token.escaped.should be_false
        token.inline.should be_false
      end
    end

    describe "second line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%[def foo])
        token.column_number.should eq(3)
        token.line_number.should eq(2)
        token.text_block.should be_false
        token.raw_text.should be_true
        token.escaped.should be_false
        token.inline.should be_false
      end
    end

    describe "third line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["\#{bar}"])
        token.column_number.should eq(5)
        token.line_number.should eq(3)
        token.text_block.should be_false
        token.raw_text.should be_true
        token.escaped.should be_false
        token.inline.should be_false
      end
    end

    describe "fourth line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%["baz"])
        token.column_number.should eq(5)
        token.line_number.should eq(4)
        token.text_block.should be_false
        token.raw_text.should be_true
        token.escaped.should be_false
        token.inline.should be_false
      end
    end

    describe "fifth line" do
      it "is a text element" do
        token = lexer.next_token

        token.type.should eq(:TEXT)
        token.value.should eq(%[end])
        token.column_number.should eq(3)
        token.line_number.should eq(5)
        token.text_block.should be_false
        token.raw_text.should be_true
        token.escaped.should be_false
        token.inline.should be_false
      end
    end
  end

  describe "inline control code" do
    string = %[div - foo_bar]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      it "is a div element" do
        token = lexer.next_token

        token.type.should eq(:ELEMENT)
        token.name.should eq("div")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
      end
    end

    describe "second line" do
      it "is a control element" do
        token = lexer.next_token

        token.type.should eq(:CONTROL)
        token.value.should eq("foo_bar")
        token.column_number.should eq(5)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end
  end

  describe "control code" do
    string = %[- foo_bar]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      it "is a control element" do
        token = lexer.next_token

        token.type.should eq(:CONTROL)
        token.value.should eq("foo_bar")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
        token.raw_text.should be_false
        token.escaped.should be_false
      end
    end
  end
end
