require "random/secure"

module Slang
  module Nodes
    class Text < Node
      def allow_children_to_escape?
        parent.allow_children_to_escape? && !text_block
      end

      def first_child?
        parent.nodes.first == self && (parent.is_a?(Element) || parent.is_a?(Document))
      end

      def empty_parent?
        parent.value =~ /^"\s*"$/ && parent.text_block
      end

      def to_s(str, buffer_name)
        str << "#{buffer_name} << \" \"\n" if prepend_whitespace
        str << "#{buffer_name} << \"\n\"\n" if raw_text && !first_child? && !text_block && !empty_parent?
        str << "#{buffer_name} << \"#{indentation[2..-1]}\"\n" if indent? && raw_text
        str << "#{buffer_name} << "

        # Escaping.
        if escaped && parent.allow_children_to_escape?
          str << "HTML.escape("
        end

        # This is an output (code) token and has children
        if token.type == :OUTPUT && children?
          sub_buffer_name = "#{buffer_name}#{Random::Secure.hex(8)}"
          str << "(#{value}\nString.build do |#{sub_buffer_name}|\n"
          nodes.each do |node|
            node.to_s(str, "#{sub_buffer_name}")
          end
          str << "end\nend)"
        else
          str << "(#{value})"
        end

        # escaping, need to close HTML.escape
        if escaped && parent.allow_children_to_escape?
          str << ".to_s)"
        end
        str << ".to_s(#{buffer_name})\n"

        if token.type != :OUTPUT && children?
          nodes.each do |node|
            node.to_s(str, buffer_name)
          end
        end
        str << "#{buffer_name} << \" \"\n" if append_whitespace
      end
    end
  end
end
