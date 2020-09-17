require "html"
require "./slang/version"
require "./slang/node"
require "./slang/document"
require "./slang/lexer"
require "./slang/parser"
require "./slang/token"
require "./slang/macros"

# require "./slang/*"

module Slang
  extend self
  DEFAULT_BUFFER_NAME = "__slang__"

  def process_string(slang, filename = "slang_#{Random.new.next_int.abs}", buffer_name = DEFAULT_BUFFER_NAME)
    Slang::Parser.new(slang, filename).parse(buffer_name)
  end

  def process_file(filename, buffer_name = DEFAULT_BUFFER_NAME)
    raise "Slang template: #{filename} doesn't exist." unless File.exists?(filename)
    process_string(File.read(filename), filename, buffer_name)
  end
end
