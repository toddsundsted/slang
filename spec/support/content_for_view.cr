require "./content_for_helper"

class ContentForView
  include ContentForHelper

  def to_s
    __content_filename__ = "spec/fixtures/content-for-helper.slang"
    String.build do |__str__|
      {{ run("./process_file", "spec/fixtures/content-for-helper.slang", "__str__") }}
    end
  end
end
