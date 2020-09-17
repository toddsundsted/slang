module ContentForHelper
  CONTENT_FOR_BLOCKS = Hash(String, Tuple(String, Proc(String))).new

  macro content_for(key, file = __FILE__)
    %proc = ->() {
      __kilt_io__ = IO::Memory.new
      {{ yield }}
      __kilt_io__.to_s
    }

    CONTENT_FOR_BLOCKS[{{key}}] = Tuple.new {{file}}, %proc
    nil
  end

  macro yield_content(key)
    if CONTENT_FOR_BLOCKS.has_key?({{key}})
      __caller_filename__ = CONTENT_FOR_BLOCKS[{{key}}][0]
      %proc = CONTENT_FOR_BLOCKS[{{key}}][1]
      %proc.call if __content_filename__ == __caller_filename__
    end
  end
end
