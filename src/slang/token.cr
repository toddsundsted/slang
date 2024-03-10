module Slang
  class Token
    # The type of token.
    property :type

    # If `text_block` is true, `column_number` is the column of the
    # markup character that begins the block of text, not the column
    # of the first text character in the block.
    property :line_number, :column_number

    # An element token's name and attributes.
    property :name, :attributes

    # The token's text representation.
    property :value

    # The token's value should be escaped (wrapped in `HTML.escape`)
    # when the token is rendered.
    property :escaped

    # The token is inline with (on the same line as) the previous
    # token.
    property :inline

    # Applies to comments. If `visible` is `true`, the markup is
    # rendered as an HTML comment. `conditional` holds the logic for
    # conditional comments.
    property :visible, :conditional

    # Indicates whether to prepend/append a space before/after the
    # token.
    property :prepend_whitespace, :append_whitespace

    # The token is part of a block of raw text.
    property :raw_text

    # The token indicates the first line of a block of verbatim text.
    property :text_block

    @name : String?
    @value : String?

    def initialize
      @type = :EOF
      @line_number = 0
      @column_number = 0
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
