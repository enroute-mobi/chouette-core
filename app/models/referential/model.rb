# frozen_string_literal: true

# Base class for Model stored into Referential
#
# Includes checksum, objectid and referential code support
#
class Referential
  class Model < Referential::ActiveRecord
    self.abstract_class = true

    include ChecksumSupport
    include ObjectidSupport
    include ReferentialCodeSupport

    # Ugly code which can be shared by a super class :-/
    # has_metadata
  end
end
