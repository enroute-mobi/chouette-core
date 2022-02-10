module Chouette
  class GroupOfLine < Chouette::ActiveRecord
    before_validation :define_line_referential

    has_metadata
    include ObjectidSupport
    include LineReferentialSupport

    belongs_to :line_provider, required: true

    has_and_belongs_to_many :lines, :class_name => 'Chouette::Line', :order => 'lines.name'

    validates_presence_of :name

    attr_reader :line_tokens

    scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }

    def self.nullable_attributes
      [:comment]
    end

    def commercial_stop_areas
      Chouette::StopArea.joins(:children => [:stop_points => [:route => [:line => :group_of_lines] ] ]).where(:group_of_lines => {:id => self.id}).distinct
    end

    def stop_areas
      Chouette::StopArea.joins(:stop_points => [:route => [:line => :group_of_lines] ]).where(:group_of_lines => {:id => self.id})
    end

    def line_tokens=(ids)
      self.line_ids = ids.split(",")
    end

    private

    def define_line_referential
      # TODO Improve performance ?
      self.line_referential ||= line_provider&.line_referential
    end
  end
end
