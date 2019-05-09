module Chouette
  class LineNotice < Chouette::ActiveRecord
    has_metadata
    include LineReferentialSupport
    include ObjectidSupport

    belongs_to :line_referential, inverse_of: :line_notices
    has_and_belongs_to_many :lines, :class_name => 'Chouette::Line', :join_table => "line_notices_lines"
    validates_presence_of :title

    alias_attribute :name, :title
  end
end
