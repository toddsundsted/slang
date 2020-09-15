require "../spec_helper"

describe Slang::Lexer do
  describe "javascript blocks" do
    string = %[javascript:\n  if (x) {\n    x;\n  }]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      token = lexer.next_token

      it "is a script element" do
        token.type.should eq(:ELEMENT)
        token.name.should eq("script")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
      end
    end

    describe "second line" do
      token = lexer.next_token

      it "is a text element" do
        token.type.should eq(:TEXT)
        token.value.should eq(%["if (x) {"])
        token.column_number.should eq(3)
        token.line_number.should eq(2)
        token.text_block.should be_false
      end
    end

    describe "third line" do
      token = lexer.next_token

      it "is a text element" do
        token.type.should eq(:TEXT)
        token.value.should eq(%["x;"])
        token.column_number.should eq(5)
        token.line_number.should eq(3)
        token.text_block.should be_false
      end
    end

    describe "fourth line" do
      token = lexer.next_token

      it "is a text element" do
        token.type.should eq(:TEXT)
        token.value.should eq(%["}"])
        token.column_number.should eq(3)
        token.line_number.should eq(4)
        token.text_block.should be_false
      end
    end
  end

  describe "css blocks" do
    string = %[css:\n  p {\n    display: none;\n  }]
    lexer = Slang::Lexer.new(string)

    describe "first line" do
      token = lexer.next_token

      it "is a style element" do
        token.type.should eq(:ELEMENT)
        token.name.should eq("style")
        token.column_number.should eq(1)
        token.line_number.should eq(1)
        token.text_block.should be_false
      end
    end

    describe "second line" do
      token = lexer.next_token

      it "is a text element" do
        token.type.should eq(:TEXT)
        token.value.should eq(%["p {"])
        token.column_number.should eq(3)
        token.line_number.should eq(2)
        token.text_block.should be_false
      end
    end

    describe "third line" do
      token = lexer.next_token

      it "is a text element" do
        token.type.should eq(:TEXT)
        token.value.should eq(%["display: none;"])
        token.column_number.should eq(5)
        token.line_number.should eq(3)
        token.text_block.should be_false
      end
    end

    describe "fourth line" do
      token = lexer.next_token

      it "is a text element" do
        token.type.should eq(:TEXT)
        token.value.should eq(%["}"])
        token.column_number.should eq(3)
        token.line_number.should eq(4)
        token.text_block.should be_false
      end
    end
  end

  describe "text blocks" do
    context "with a pipe" do
      string = %[| First line.\n  Second line.]
      lexer = Slang::Lexer.new(string)

      describe "first line" do
        token = lexer.next_token

        it "is a text element" do
          token.type.should eq(:TEXT)
          token.value.should eq(%["First line."])
          token.column_number.should eq(1)
          token.line_number.should eq(1)
          token.append_whitespace.should be_false
          token.text_block.should be_true
        end
      end

      describe "second line" do
        token = lexer.next_token

        it "is a text element" do
          token.type.should eq(:TEXT)
          token.value.should eq(%["Second line."])
          token.column_number.should eq(3)
          token.line_number.should eq(2)
          token.append_whitespace.should be_false
          token.text_block.should be_false
        end
      end
    end

    context "with a quote" do
      string = %[' First line.\n  Second line.]
      lexer = Slang::Lexer.new(string)

      describe "first line" do
        token = lexer.next_token

        it "is a text element" do
          token.type.should eq(:TEXT)
          token.value.should eq(%["First line."])
          token.column_number.should eq(1)
          token.line_number.should eq(1)
          token.append_whitespace.should be_true
          token.text_block.should be_true
        end
      end

      describe "second line" do
        token = lexer.next_token

        it "is a text element" do
          token.type.should eq(:TEXT)
          token.value.should eq(%["Second line."])
          token.column_number.should eq(3)
          token.line_number.should eq(2)
          token.append_whitespace.should be_false
          token.text_block.should be_false
        end
      end
    end
  end
end
