module Slang
  class Parser
    @current_node : Node

    def initialize(string, filename : String? = nil)
      @lexer = Lexer.new(string)
      @document = Document.new(filename)
      @current_node = @document
      @control_nodes_per_column = {} of Int32 => Nodes::Control
      next_token
    end

    def document
      loop do
        case token.type
        when :EOF
          break
        when :DOCTYPE
          @document.nodes << Nodes::Doctype.new(@document, token)
          next_token
        when :ATTRIBUTE
          parent = @current_node
          # find the parent
          until parent.is_a?(Nodes::Element)
            parent = parent.parent
          end
          parent.nodes << Nodes::Attribute.new(parent, token)
          next_token
        when :ELEMENT, :COMMENT, :CONTROL, :CODE, :OUTPUT, :TEXT
          parent = @current_node
          # find the parent
          until parent.is_a?(Document)
            # column number is smaller than the node we're processing
            # therefore it is the parent
            break if parent.column_number < token.column_number
            if parent.token.type.in?(:ELEMENT, :CONTROL, :OUTPUT) && parent.token.inline
              break if parent.parent.column_number < token.column_number
            end
            parent = parent.parent
          end
          node = case token.type
                 when :ELEMENT
                   Nodes::Element.new(parent, token)
                 when :COMMENT
                   Nodes::Comment.new(parent, token)
                 when :CONTROL
                   Nodes::Control.new(parent, token)
                 when :CODE
                   Nodes::Code.new(parent, token)
                 else
                   Nodes::Text.new(parent, token)
                 end
          if node.is_a?(Nodes::Element)
            node.attributes.each do |name, values|
              if values.is_a?(String)
                attribute = Token.new
                attribute.type = :ATTRIBUTE
                attribute.name = name
                attribute.value = values
                attribute.line_number = token.line_number
                attribute.column_number = token.column_number
                attribute.escaped = false
                node.nodes << Nodes::Attribute.new(node, attribute)
              else
                values.each do |value|
                  attribute = Token.new
                  attribute.type = :ATTRIBUTE
                  attribute.name = name
                  attribute.value = value
                  attribute.line_number = token.line_number
                  attribute.column_number = token.column_number
                  attribute.escaped = false
                  node.nodes << Nodes::Attribute.new(node, attribute)
                end
              end
            end
            parent.nodes << node
          elsif node.is_a?(Nodes::Control)
            if @control_nodes_per_column[node.column_number]?
              last_control_node = @control_nodes_per_column[node.column_number]
              if last_control_node.allow_branch?(node)
                last_control_node.branches << node
              else
                @control_nodes_per_column[node.column_number] = node
                parent.nodes << node
              end
            else
              @control_nodes_per_column[node.column_number] = node
              parent.nodes << node
            end
          else
            parent.nodes << node
          end
          @current_node = node
          next_token
        else
          unexpected_token
        end
      end

      @document
    end

    def parse(io_name = Slang::DEFAULT_BUFFER_NAME)
      String.build do |str|
        document.to_s(str, io_name)
      end
    end

    private delegate token, to: @lexer
    private delegate next_token, to: @lexer

    private def unexpected_token
      raise "unexpected token '#{token}'"
    end
  end
end
