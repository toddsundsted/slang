private def render(node, str)
  if (value = node.value) && !value.empty?
    str << node.indentation[2..-1] if node.indent?
    value.gsub(/\\(.)/, "\\1")[1..-2].to_s(str)
    str << "\n"
  end
  node.nodes.each do |nodex|
    render(nodex, str)
  end
end

module Slang
  module Nodes
    class Code < Node
      def to_s(str, buffer_name)
        render(self, str)
      end
    end
  end
end
