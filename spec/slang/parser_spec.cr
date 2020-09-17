require "../spec_helper"

module Slang
  class Node
    def expansion
      nodes.reduce([{self.class, column_number, line_number, value, nodes.size}]) do |acc, node|
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
        {Slang::Nodes::Element, 1, 1, nil, 2},
        {Slang::Nodes::Text, 3, 2, %["if (x) {"], 1},
        {Slang::Nodes::Text, 5, 3, %["x;"], 0},
        {Slang::Nodes::Text, 3, 4, %["}"], 0}
      ])
    end

    it "renders the template code" do
      parser.parse.should eq <<-BLOCK
      __slang__ << "<script"
      __slang__ << ">"
      __slang__ << ""
      __slang__ << ("if (x) {").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << "  "
      __slang__ << ("x;").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << ""
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
        {Slang::Nodes::Element, 1, 1, nil, 2},
        {Slang::Nodes::Text, 3, 2, %["p {"], 1},
        {Slang::Nodes::Text, 5, 3, %["display: none;"], 0},
        {Slang::Nodes::Text, 3, 4, %["}"], 0}
      ])
    end

    it "renders the template code" do
      parser.parse.should eq <<-BLOCK
      __slang__ << "<style"
      __slang__ << ">"
      __slang__ << ""
      __slang__ << ("p {").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << "  "
      __slang__ << ("display: none;").to_s(__slang__)
      __slang__ << "\n"
      __slang__ << ""
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
        __slang__ << ""
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
        __slang__ << ""
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
        {Slang::Nodes::Text, 3, 2, %["def foo"], 1},
        {Slang::Nodes::Text, 5, 3, %["\\\"foo\\\""], 0},
        {Slang::Nodes::Text, 3, 4, %["end"], 0}
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
end
