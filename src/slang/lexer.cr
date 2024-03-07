module Slang
  class Lexer
    RAWSTUFF = {"javascript:": "script", "css:": "style", "crystal:": "*code*"}

    ATTR_OPEN_CLOSE_MAP = {
      '{' => '}',
      '[' => ']',
      '(' => ')',
      ' ' => ' ',
    }

    STRING_OPEN_CLOSE_CHARS_MAP = {
      '(' => ')',
      '{' => '}',
      '[' => ']',
      '<' => '>',
    }

    getter token

    def initialize(string)
      @reader = Char::Reader.new(string)
      @token = Token.new
      @parsing_text = false
      @code_block_column_number = 0
      @line_number = 1
      @column_number = 1
      @last_token = @token
      @last_delimiter = ' '
      @raw_text_column = 0
    end

    def next_token
      loop do
        next_token_internal
        break unless @token.type == :NEWLINE || @token.type == :WRAPPER
      end
      @last_token = @token
      @token
    end

    private def next_token_internal
      skip_whitespace unless @parsing_text

      @token = Token.new
      @token.line_number = @line_number
      @token.column_number = @column_number

      if @raw_text_column > 0 && @column_number < @raw_text_column
        @raw_text_column = 0
      end

      inline = @raw_text_column > 0 || (@last_token.type.in?([:ELEMENT, :ATTRIBUTE, :TEXT]) && @last_token.line_number == @line_number)

      if @column_number <= @code_block_column_number
        @code_block_column_number = 0
      end

      if @code_block_column_number > 0
        case current_char
        when '\0'
          @token.type = :EOF
        when '\r'
          raise "slang expected '\\n' after '\\r'" unless next_char == '\n' # peek_next_char???
          consume_newline
        when '\n'
          consume_newline
        else
          @token.type = :TEXT
          @token.value = consume_line
          @token.raw_text = true
          @token.escaped = false
          text = @token.value || ""
          @raw_text_column = (@column_number - text.size)
        end
        return
      end

      case current_char
      when '\0'
        @token.type = :EOF
      when '\r'
        raise "slang expected '\\n' after '\\r'" unless next_char == '\n'
        consume_newline
      when '\n'
        consume_newline
      when '.', '#', .ascii_letter?
        if inline
          if current_char.ascii_letter?
            current_attr_name = consume_html_valid_name
            if current_char == '='
              open_char = @last_delimiter
              close_char = ATTR_OPEN_CLOSE_MAP[@last_delimiter]
              current_attr_value = consume_value(open_char, close_char)
              @token.type = :ATTRIBUTE
              @token.name = current_attr_name
              @token.value = current_attr_value
            else
              go_back(current_attr_name.size, current_attr_name.bytesize)
              @token.escaped = false
              consume_text
            end
          elsif current_char == '#' && peek_next_char == '{'
            consume_string_interpolation_text
          else
            @token.escaped = false
            consume_text
          end
        else
          @token.escaped = false
          consume_element
        end
      when ':'
        @token.escaped = false
        consume_inline_element
      when '-'
        @token.escaped = false
        consume_control
      when '='
        consume_output
      when '|', '\''
        @token.escaped = false
        @token.text_block = true
        @token.append_whitespace = (current_char == '\'')
        next_char ; skip_whitespace ; consume_text
        text = @token.value || ""
        @raw_text_column = (@column_number - text.size) + 2 # +2 for the quotation marks
      when '<'
        @token.escaped = false
        consume_text
      when '/'
        consume_comment
      else
        if inline
          # matching pairs of open/close chars should be ignored
          if current_char.in?(ATTR_OPEN_CLOSE_MAP.keys) && @last_token.type == :ELEMENT
            @token.type = :WRAPPER
            @last_delimiter = current_char
            next_char
          elsif current_char.in?(ATTR_OPEN_CLOSE_MAP.values) && @last_token.type == :ATTRIBUTE
            @token.type = :WRAPPER
            @last_delimiter = current_char
            next_char
          else
            @token.escaped = false
            consume_text
          end
        else
          unexpected_char
        end
      end

      @token.raw_text = (@raw_text_column > 0)
      @token.inline = inline unless @raw_text_column > 0

      if @token.type == :TEXT
        if @last_token.line_number == @token.line_number && @last_token.column_number < @token.column_number
            @token.inline = true
        end
      end
    end

    private def consume_element
      @token.type = :ELEMENT
      @token.name = "div"

      loop do
        case current_char
        when .ascii_letter?
          consume_element_name
        when '.'
          next_char # skip the '.' at the beginning
          consume_element_class
        when '#'
          next_char # skip the '#' at the beginning
          consume_element_id
        when '<'
          @token.prepend_whitespace = true
          next_char
        when '>'
          @token.append_whitespace = true
          next_char
        else
          break
        end
      end
    end

    private def consume_inline_element
      next_char # skip ':'
      skip_whitespace
      consume_element
    end

    private def consume_element_name
      column_number = @column_number
      @token.name = check_raw_text_header(consume_html_valid_name)
      if @token.name == "doctype"
        @token.type = :DOCTYPE
        next_char if current_char == ' '
        @token.value = consume_line
      elsif @token.name == "*code*"
        @code_block_column_number = column_number
        @token.type = :CODE
        @token.name = nil
        consume_line
      end
    end

    private def consume_element_class
      @token.add_attribute "class", consume_html_valid_name.inspect, false
    end

    private def consume_element_id
      @token.add_attribute "id", consume_html_valid_name.inspect, false
    end

    private def consume_html_valid_name
      String.build do |str|
        loop do
          case current_char
          when ':'
            break if ATTR_OPEN_CLOSE_MAP.keys.includes? peek_next_char
          when .alphanumeric?, '-', '_'
            # continue
          else
            break
          end

          str << current_char
          next_char
        end
      end
    end

    private def check_raw_text_header(name : String)
      if RAWSTUFF.has_key?(name)
        @raw_text_column = (@column_number - name.size) + 2
        RAWSTUFF[name]
      else
        name
      end
    end

    private def consume_comment
      @token.type = :COMMENT
      next_char
      if current_char == '!'
        @token.visible = true
        next_char
      elsif current_char == '['
        @token.visible = true
        next_char
        @token.conditional = String.build do |str|
          loop do
            case current_char
            when ']'
              next_char
              break
            when '\0', '\n'
              break
            when '\r'
              raise "slang expected '\\n' after '\\r'" unless next_char == '\n'
            else
              str << current_char
              next_char
            end
          end
        end
      else
        @token.visible = false
      end
      skip_whitespace
      @token.value = consume_line if @token.conditional.empty?
    end

    private def consume_control
      @token.type = :CONTROL
      next_char
      next_char if current_char == ' '
      @token.value = consume_line
    end

    private def consume_output
      @token.type = :OUTPUT
      append_whitespace = false
      prepend_whitespace = false
      next_char
      if current_char == '='
        @token.escaped = false
        next_char
      end
      if current_char == '<'
        prepend_whitespace = true
        next_char
      end
      if current_char == '>'
        append_whitespace = true
        next_char
      end

      skip_whitespace
      @token.value = consume_line.strip
      @token.value = " #{@token.value}" if prepend_whitespace
      @token.value = "#{@token.value} " if append_whitespace
    end

    private def consume_text
      @token.type = :TEXT
      @token.value = "\"#{consume_text_line}\""
      @parsing_text = true
    end

    private def consume_text_line
      consume_string escape_double_quotes: true
    end

    private def consume_string_interpolation_text
      @token.type = :TEXT
      next_char ; next_char # skip '#{'
      @token.value = consume_string_interpolation
    end

    private def consume_string_interpolation
      maybe_string = false
      String.build do |str|
        loop do
          if current_char == '%'
            maybe_string = true
          end
          if maybe_string && STRING_OPEN_CLOSE_CHARS_MAP.has_key? current_char
            oc = current_char
            cc = STRING_OPEN_CLOSE_CHARS_MAP[current_char]
            str << current_char
            next_char
            str << consume_string open_char: oc, close_char: cc, break_on_interpolation: false
            next
          end
          if current_char == '"' || current_char == '\''
            ch = current_char
            str << current_char
            next_char
            str << consume_string open_char: ch, close_char: ch, break_on_interpolation: false
            next
          end
          if current_char == '}'
            next_char
            break
          end

          if current_char == '\n' || current_char == '\0'
            break
          else
            str << current_char
            next_char
          end
        end
      end
    end

    private def consume_string(open_char = '"', close_char = '"', *, escape_double_quotes = false, break_on_interpolation = true)
      level = 0
      escaped = false
      maybe_string_interpolation = false
      String.build do |str|
        loop do
          if escape_double_quotes
            if current_char == '"'
              str << "\\\""
              next_char
              next
            end
          else
            if (close_char == '"' || close_char == '\'') && current_char == close_char && !escaped
              str << current_char
              next_char
              break
            end

            if current_char == open_char && !escaped && !maybe_string_interpolation
              level += 1
            end
            if current_char == close_char && !escaped
              if level == 0
                str << current_char
                next_char
                break
              end
              level -= 1
            end
          end

          if maybe_string_interpolation
            maybe_string_interpolation = false
            if current_char == '{'
              str << consume_string_interpolation
              str << '}'
              next
            end
          end
          if current_char == '#' && !escaped
            maybe_string_interpolation = true
            if peek_next_char == '{' && break_on_interpolation
              break
            end
          end

          if current_char == '\\' && !escaped
            escaped = true
          else
            escaped = false
          end

          if current_char == '\n' || current_char == '\0'
            break
          else
            str << current_char
            next_char
          end
        end
      end
    end

    private def consume_line
      String.build do |str|
        loop do
          if current_char == '\n' || current_char == '\0'
            break
          else
            str << current_char
            next_char
          end
        end
      end
    end

    private def consume_value(open_char, close_char)
      String.build do |str|
        open_count = 0

        is_str = false
        is_in_parenthesis = false
        is_in_interpolation = false
        loop do
          case current_char
          when '='
            next_char
            if current_char == '"'
              ch = current_char
              str << current_char
              next_char
              str << consume_string open_char: ch, close_char: ch, break_on_interpolation: false
              break
            end
          when ' '
            break if open_count == 0
            break unless is_in_parenthesis
            str << current_char
            next_char
          when open_char
            next if open_char == ' '
            open_count += 1
            str << current_char
            next_char
          when close_char
            next if close_char == ' '
            break if open_count == 0
            open_count -= 1
            str << current_char
            next_char
          when '('
            open_count += 1
            is_in_parenthesis = true
            str << current_char
            next_char
          when ')'
            open_count -= 1
            is_in_parenthesis = false
            str << current_char
            next_char
          when '\n', '\0'
            break
          else
            str << current_char
            next_char
          end
        end
      end
    end

    private def consume_newline
      @line_number += 1
      @column_number = 0
      loop do
        case next_char
        when '\r'
          raise "slang expected '\\n' after '\\r'" unless next_char == '\n'
        when '\n'
          # Nothing
        else
          break
        end
        @line_number += 1
        @column_number = 0
      end
      @parsing_text = false
      @token.line_number = @line_number
      @token.column_number = @column_number
      @token.type = :NEWLINE
    end

    private def go_back(column, bytes)
      @column_number -= column
      @reader.pos -= bytes
    end

    private def next_char
      @column_number += 1
      @reader.next_char
    end

    private def peek_next_char
      @reader.peek_next_char
    end

    private def current_char
      @reader.current_char
    end

    private def skip_whitespace
      while current_char == ' ' || current_char == '\t'
        next_char
      end
    end

    private def unexpected_char(char = current_char)
      raise "unexpected char '#{char}'"
    end
  end
end
