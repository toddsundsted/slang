module Slang
  module Nodes
    class Code < Node
      private def render(node, str)
        if (value = node.value.presence)
          str << node.indentation if node.indent?
          value.to_s(str)
          str << "\n"
        end
        node.nodes.each do |node|
          render(node, str)
        end
      end

      def to_s(str, buffer_name)
        render(self, str)
      end
    end
  end
end
