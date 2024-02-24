module Slang
  class Token
    property :type
    property :line_number, :column_number

    # elements
    property :name, :attributes

    property :value, :escaped, :inline, :visible, :conditional, :prepend_whitespace, :append_whitespace

    # The token is part of a block of raw text.
    property :raw_text

    # The token is the first line of a block of verbatim text.
    property :text_block

    @value : String?
    @id : String?

    def initialize
      @type = :EOF
      @line_number = 0
      @column_number = 0
      @name = "div"
      @attributes = {} of String => (String | Set(String))
      @escaped = true
      @inline = false
      @visible = true
      @conditional = ""
      @attributes["class"] = Set(String).new
      @prepend_whitespace = false
      @append_whitespace = false
      @raw_text = false
      @text_block = false
    end

    def add_attribute(name, value, interpolate)
      if name == "class"
        value = "\#{#{value}}" if interpolate
        (@attributes["class"].as Set) << value
      else
        @attributes[name] = value
      end
    end
  end
end
