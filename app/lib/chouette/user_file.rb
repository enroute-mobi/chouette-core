# Regroups attributes of file sent to the user (like export or import files)
module Chouette
  class UserFile

    attr_accessor :basename, :extension, :content_type

    def initialize(attributes = {})
      attributes.each { |k,v| send "#{k}=", v }
    end

    def name
      "#{basename}.#{extension}"
    end

  end
end
