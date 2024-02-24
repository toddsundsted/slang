module Slang
  module Nodes
    class Attribute < Node
      delegate :name, :value, to: @token

      def id?
        name == "id"
      end

      def class?
        name == "class"
      end

      def id_or_class?
        id? || class?
      end

      def to_s(str, buffer_name)
        # class Element handles rendering
      end
    end
  end
end
