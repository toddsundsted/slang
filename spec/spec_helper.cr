require "spec"
require "../src/slang"

require "./support/form_view"

macro render_file(filename)
  String.build do |__str__|
    \{{ run("./support/process_file", {{filename}}, "__str__") }}
  end
end

macro render(slang)
  String.build do |__str__|
    \{{ run("./support/process", {{slang}}, "__str__") }}
  end
end

def evaluates_to_true
  1 == 1
end

def evaluates_to_false
  1 == 2
end

def evaluates_to_hello
  "hello"
end
