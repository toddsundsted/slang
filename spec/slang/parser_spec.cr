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
    end
  end
end
