require "../spec_helper"

module Slang
  class Node
    def expansion
      nodes.reduce([{self.class, column_number, line_number, value || name, nodes.size}]) do |acc, node|
        acc + node.expansion
      end
    end
  end
end

describe Slang::Parser do
  describe "javascript blocks" do
    string = %[javascript:\n  if (x) {\n    x;\n  }]
    parser = Slang::Parser.new(string)

    it "parses the javascript block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 1},
        {Slang::Nodes::Element, 1, 1, "script", 2},
        {Slang::Nodes::Text, 3, 2, %["if (x) {"], 1},
        {Slang::Nodes::Text, 5, 3, %["x;"], 0},
        {Slang::Nodes::Text, 3, 4, %["}"], 0}
      ])
    end

    it "renders the template code" do
      parser.parse.should eq <<-BLOCK
      __slang__ << "<script"
      __slang__ << ">"
      __slang__ << ("if (x) {").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << "  "
      __slang__ << ("x;").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << ("}").to_s(__slang__)
      __slang__ << "</script>"

      BLOCK
    end
  end

  describe "css blocks" do
    string = %[css:\n  p {\n    display: none;\n  }]
    parser = Slang::Parser.new(string)

    it "parses the css block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 1},
        {Slang::Nodes::Element, 1, 1, "style", 2},
        {Slang::Nodes::Text, 3, 2, %["p {"], 1},
        {Slang::Nodes::Text, 5, 3, %["display: none;"], 0},
        {Slang::Nodes::Text, 3, 4, %["}"], 0}
      ])
    end

    it "renders the template code" do
      parser.parse.should eq <<-BLOCK
      __slang__ << "<style"
      __slang__ << ">"
      __slang__ << ("p {").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << "  "
      __slang__ << ("display: none;").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << ("}").to_s(__slang__)
      __slang__ << "</style>"

      BLOCK
    end
  end

  describe "text blocks" do
    context "with a pipe" do
      string = %[| First line.\n  Second line.\n    Third line.]
      parser = Slang::Parser.new(string)

      it "parses the text block" do
        parser.document.expansion.should eq([
          {Slang::Document, 1, 0, nil, 1},
          {Slang::Nodes::Text, 1, 1, %["First line."], 1},
          {Slang::Nodes::Text, 3, 2, %["Second line."], 1},
          {Slang::Nodes::Text, 5, 3, %["Third line."], 0}
        ])
      end

      it "renders the template code" do
        parser.parse.should eq <<-BLOCK
        __slang__ << ("First line.").to_s(__slang__)
        __slang__ << "\n"
        __slang__ << ("Second line.").to_s(__slang__)
        __slang__ << "\n"
        __slang__ << "  "
        __slang__ << ("Third line.").to_s(__slang__)

        BLOCK
      end
    end

    context "with a quote" do
      string = %[' First line.\n  Second line.\n    Third line.]
      parser = Slang::Parser.new(string)

      it "parses the text block" do
        parser.document.expansion.should eq([
          {Slang::Document, 1, 0, nil, 1},
          {Slang::Nodes::Text, 1, 1, %["First line."], 1},
          {Slang::Nodes::Text, 3, 2, %["Second line."], 1},
          {Slang::Nodes::Text, 5, 3, %["Third line."], 0}
        ])
      end

      it "renders the template code" do
        parser.parse.should eq <<-BLOCK
        __slang__ << ("First line.").to_s(__slang__)
        __slang__ << "\n"
        __slang__ << ("Second line.").to_s(__slang__)
        __slang__ << "\n"
        __slang__ << "  "
        __slang__ << ("Third line.").to_s(__slang__)
        __slang__ << " "

        BLOCK
      end
    end
  end

  describe "code blocks" do
    string = %[crystal:\n  def foo\n    "foo"\n  end]
    parser = Slang::Parser.new(string)

    it "parses the code block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 1},
        {Slang::Nodes::Code, 1, 1, nil, 2},
        {Slang::Nodes::Text, 3, 2, %[def foo], 1},
        {Slang::Nodes::Text, 5, 3, %["foo"], 0},
        {Slang::Nodes::Text, 3, 4, %[end], 0}
      ])
    end

      it "renders the template code" do
        parser.parse.should eq <<-BLOCK
        def foo
          "foo"
        end

        BLOCK
      end
  end

  describe "control block ending in do" do
    string = %[div\n  - foo_bar do |i|\n    baz = i\ndiv]
    parser = Slang::Parser.new(string)

    it "parses the code block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 2},
        {Slang::Nodes::Element, 1, 1, "div", 1},
        {Slang::Nodes::Control, 3, 2, "foo_bar do |i|", 1},
        {Slang::Nodes::Element, 5, 3, "baz", 1},
        {Slang::Nodes::Text, 9, 3, "i", 0},
        {Slang::Nodes::Element, 1, 4, "div", 0}
      ])
    end
  end

  describe "control block ending in do" do
    string = %[div - foo_bar do |i|\n  baz = i\ndiv]
    parser = Slang::Parser.new(string)

    it "parses the code block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 2},
        {Slang::Nodes::Element, 1, 1, "div", 1},
        {Slang::Nodes::Control, 5, 1, "foo_bar do |i|", 1},
        {Slang::Nodes::Element, 3, 2, "baz", 1},
        {Slang::Nodes::Text, 7, 2, "i", 0},
        {Slang::Nodes::Element, 1, 3, "div", 0}
      ])
    end
  end

  describe "output block ending in do" do
    string = %[div\n  == foo_bar do\n    baz\ndiv]
    parser = Slang::Parser.new(string)

    it "parses the code block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 2},
        {Slang::Nodes::Element, 1, 1, "div", 1},
        {Slang::Nodes::Text, 3, 2, "foo_bar do", 1},
        {Slang::Nodes::Element, 5, 3, "baz", 0},
        {Slang::Nodes::Element, 1, 4, "div", 0}
      ])
    end
  end

  describe "output block ending in do" do
    string = %[div == foo_bar do\n  baz\ndiv]
    parser = Slang::Parser.new(string)

    it "parses the code block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 2},
        {Slang::Nodes::Element, 1, 1, "div", 1},
        {Slang::Nodes::Text, 5, 1, "foo_bar do", 1},
        {Slang::Nodes::Element, 3, 2, "baz", 0},
        {Slang::Nodes::Element, 1, 3, "div", 0}
      ])
    end
  end

  describe "two tags" do
    string = %[div\ndiv]
    parser = Slang::Parser.new(string)

    it "parses the code block" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 2},
        {Slang::Nodes::Element, 1, 1, "div", 0},
        {Slang::Nodes::Element, 1, 2, "div", 0}
      ])
    end
  end

  describe "tag with attributes" do
    string = %[div class="foo" id=bar type=baz]
    parser = Slang::Parser.new(string)

    it "parses the element with attributes" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 1},
        {Slang::Nodes::Element, 1, 1, "div", 3},
        {Slang::Nodes::Attribute, 5, 1, %["foo"], 0},
        {Slang::Nodes::Attribute, 17, 1, %[bar], 0},
        {Slang::Nodes::Attribute, 24, 1, %[baz], 0}
      ])
    end

    it "renders the template code" do
      parser.parse.should eq <<-BLOCK
      __slang__ << "<div"
      __slang__ << " id=\\\""
      ::HTML.escape((bar).to_s, __slang__)
      __slang__ << "\\\""
      __slang__ << " class=\\\""
      ::Slang.let("foo") do |__value__|
      if __value__.to_s.presence
      ::HTML.escape(__value__.to_s, __slang__)
      end
      end
      __slang__ << "\\\""
      ::Slang.let(baz) do |__value__|
      unless __value__ == false
      __slang__ << " type"
      unless __value__ == true
      __slang__ << "=\\\""
      ::HTML.escape(__value__.to_s, __slang__)
      __slang__ << "\\\""
      end
      end
      end
      __slang__ << ">"
      __slang__ << "</div>"

      BLOCK
    end
  end

  describe "tag with shortcuts" do
    string = %[span.foo#bar type=baz]
    parser = Slang::Parser.new(string)

    it "parses the element with attributes" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 1},
        {Slang::Nodes::Element, 1, 1, "span", 3},
        {Slang::Nodes::Attribute, 1, 1, %["foo"], 0}, # FIXME: This should be 5
        {Slang::Nodes::Attribute, 1, 1, %["bar"], 0}, # FIXME: This should be 9
        {Slang::Nodes::Attribute, 14, 1, %[baz], 0}
      ])
    end

    it "renders the template code" do
      parser.parse.should eq <<-BLOCK
      __slang__ << "<span"
      __slang__ << " id=\\\""
      (\"bar\").to_s(__slang__)
      __slang__ << "\\\""
      __slang__ << " class=\\\""
      ::Slang.let("foo") do |__value__|
      if __value__.to_s.presence
      __value__.to_s(__slang__)
      end
      end
      __slang__ << "\\\""
      ::Slang.let(baz) do |__value__|
      unless __value__ == false
      __slang__ << " type"
      unless __value__ == true
      __slang__ << "=\\\""
      ::HTML.escape(__value__.to_s, __slang__)
      __slang__ << "\\\""
      end
      end
      end
      __slang__ << ">"
      __slang__ << "</span>"

      BLOCK
    end
  end

  describe "inline tag" do
    string = %[div: div\n  | foo]
    parser = Slang::Parser.new(string)

    it "parses the inline tag" do
      parser.document.expansion.should eq([
        {Slang::Document, 1, 0, nil, 1},
        {Slang::Nodes::Element, 1, 1, "div", 1},
        {Slang::Nodes::Element, 4, 1, "div", 1},
        {Slang::Nodes::Text, 3, 2, %["foo"], 0}
      ])
    end

    it "renders the template code" do
      parser.parse.should eq <<-BLOCK
      __slang__ << "<div"
      __slang__ << ">"
      __slang__ << "<div"
      __slang__ << ">"
      __slang__ << ("foo").to_s(__slang__)
      __slang__ << "</div>"
      __slang__ << "</div>"

      BLOCK
    end
  end

  describe "interpolation" do
    context "tag with interpolation" do
      string = %[div foo \#{bar} baz]
      parser = Slang::Parser.new(string)

      it "parses the tag with interpolation" do
        parser.document.expansion.should eq([
          {Slang::Document, 1, 0, nil, 1},
          {Slang::Nodes::Element, 1, 1, "div", 1},
          {Slang::Nodes::Text, 5, 1, %["foo "], 1},
          {Slang::Nodes::Text, 9, 1, "bar", 1},
          {Slang::Nodes::Text, 15, 1, %[" baz"], 0}
        ])
      end

      it "renders the template code" do
        parser.parse.should eq <<-BLOCK
        __slang__ << "<div"
        __slang__ << ">"
        __slang__ << ("foo ").to_s(__slang__)
        __slang__ << ::HTML.escape((bar).to_s).to_s(__slang__)
        __slang__ << (" baz").to_s(__slang__)
        __slang__ << "</div>"

        BLOCK
      end
    end

    context "text with interpolation" do
      string = %[| foo \#{bar} baz]
      parser = Slang::Parser.new(string)

      it "parses the text with interpolation" do
        parser.document.expansion.should eq([
          {Slang::Document, 1, 0, nil, 1},
          {Slang::Nodes::Text, 1, 1, %["foo "], 1},
          {Slang::Nodes::Text, 7, 1, "bar", 1},
          {Slang::Nodes::Text, 13, 1, %[" baz"], 0}
        ])
      end

      it "renders the template code" do
        parser.parse.should eq <<-BLOCK
        __slang__ << ("foo ").to_s(__slang__)
        __slang__ << ::HTML.escape((bar).to_s).to_s(__slang__)
        __slang__ << (" baz").to_s(__slang__)

        BLOCK
      end
    end
  end
end
