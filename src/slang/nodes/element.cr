module Slang
  module Nodes
    class Element < Node
      SELF_CLOSING_TAGS = %w{area base br col embed hr img input keygen link menuitem meta param source track wbr}
      RAW_TEXT_TAGS     = %w(script style)

      delegate :name, :attributes, to: @token

      def self_closing?
        SELF_CLOSING_TAGS.includes?(name)
      end

      def allow_children_to_escape?
        !RAW_TEXT_TAGS.includes?(name)
      end

      def to_s(str, buffer_name)
        str << "#{buffer_name} << \" \"\n" if prepend_whitespace
        str << "#{buffer_name} << \"<#{name}\"\n"
        if (attribute = select_attributes.find(&.id?))
          str << "#{buffer_name} << \" id=\\\"\"\n"
          if attribute.escaped
            str << "::HTML.escape((#{attribute.value}).to_s, #{buffer_name})\n"
          else
            str << "(#{attribute.value}).to_s(#{buffer_name})\n"
          end
          str << "#{buffer_name} << \"\\\"\"\n"
        end
        unless (attributes = select_attributes.select(&.class?)).empty?
          str << "#{buffer_name} << \" class=\\\"\"\n"
          attributes.each_with_index do |attribute, i|
            str << "if (#{attribute.value}).presence\n"
            str << "#{buffer_name} << \" \"\n" if i > 0
            if attribute.escaped
              str << "::HTML.escape((#{attribute.value}).to_s, #{buffer_name})\n"
            else
              str << "(#{attribute.value}).to_s(#{buffer_name})\n"
            end
            str << "end\n"
          end
          str << "#{buffer_name} << \"\\\"\"\n"
        end
        select_attributes.reject(&.id_or_class?).each do |attribute|
          name, value = attribute.name, attribute.value
          # remove the attribute if value evaluates to false
          # remove the value if value evaluates to true
          str << "unless (#{value}) == false\n"
          str << "#{buffer_name} << \" #{name}\"\n"
          str << "unless (#{value}) == true\n"
          str << "#{buffer_name} << \"=\\\"\"\n"
          str << "::HTML.escape((#{value}).to_s, #{buffer_name})\n"
          str << "#{buffer_name} << \"\\\"\"\n"
          str << "end\n"
          str << "end\n"
        end
        str << "#{buffer_name} << \">\"\n"
        if children?
          nodes.each do |node|
            node.to_s(str, buffer_name)
          end
        end
        if !self_closing?
          str << "#{buffer_name} << \"</#{name}>\"\n"
        end
        str << "#{buffer_name} << \" \"\n" if append_whitespace
      end

      private def select_attributes
        nodes.select(Attribute)
      end
    end
  end
end
