require "../spec_helper"

describe Slang::Node do
  describe "#indentation_spaces" do
    describe "javascript blocks" do
      string = %[a\n  b\n    javascript:\n      if (x) {\n        x();\n      }]
      parser = Slang::Parser.new(string)
      document = parser.document

      context "first node" do
        text = document.nodes[0].nodes[0].nodes[0]

        it "should equal 0" do
          text.name.should eq("script")
          text.indentation_spaces.should eq(0)
        end
      end

      context "second node" do
        text = document.nodes[0].nodes[0].nodes[0].nodes[0]

        it "should equal 0" do
          text.value.should eq(%["if (x) {"])
          text.indentation_spaces.should eq(0)
        end
      end

      context "third node" do
        text = document.nodes[0].nodes[0].nodes[0].nodes[0].nodes[0]

        it "should equal 2" do
          text.value.should eq(%["x();"])
          text.indentation_spaces.should eq(2)
        end
      end
    end

    describe "css blocks" do
      string = %[a\n  b\n    css:\n      p {\n        display: none;\n      }]
      parser = Slang::Parser.new(string)
      document = parser.document

      context "first node" do
        text = document.nodes[0].nodes[0].nodes[0]

        it "should equal 0" do
          text.name.should eq("style")
          text.indentation_spaces.should eq(0)
        end
      end

      context "second node" do
        text = document.nodes[0].nodes[0].nodes[0].nodes[0]

        it "should equal 0" do
          text.value.should eq(%["p {"])
          text.indentation_spaces.should eq(0)
        end
      end

      context "third node" do
        text = document.nodes[0].nodes[0].nodes[0].nodes[0].nodes[0]

        it "should equal 2" do
          text.value.should eq(%["display: none;"])
          text.indentation_spaces.should eq(2)
        end
      end
    end

    describe "text blocks" do
      string = %[a\n  b\n    | A\n      B\n        C]
      parser = Slang::Parser.new(string)
      document = parser.document

      context "first node" do
        text = document.nodes[0].nodes[0].nodes[0]

        it "should equal 0" do
          text.value.should eq(%["A"])
          text.indentation_spaces.should eq(0)
        end
      end

      context "second node" do
        text = document.nodes[0].nodes[0].nodes[0].nodes[0]

        it "should equal 0" do
          text.value.should eq(%["B"])
          text.indentation_spaces.should eq(0)
        end
      end

      context "third node" do
        text = document.nodes[0].nodes[0].nodes[0].nodes[0].nodes[0]

        it "should equal 2" do
          text.value.should eq(%["C"])
          text.indentation_spaces.should eq(2)
        end
      end
    end
  end
end
