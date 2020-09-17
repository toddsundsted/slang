module Slang
  class Document < Node
    def initialize(@filename : String? = nil)
      @token = Token.new
      @token.column_number = 1
      @parent = self
    end

    def document?
      true
    end

    def to_s(str, buffer_name)
      str << %{#<loc:push>#<loc:"#{@filename}",1,1>\n} if @filename
      super
      str << %{#<loc:pop>\n} if @filename
    end
  end
end
