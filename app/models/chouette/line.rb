module Chouette
  class Line < Chouette::ActiveRecord
    has_metadata
    include LineRestrictions
    include LineReferentialSupport
    include ObjectidSupport
    include StifTransportModeEnumerations
    include StifTransportSubmodeEnumerations


    include ColorSupport
    color_attribute
    color_attribute :text_color, %w(000000 9B9B9B FFFFFF)

    belongs_to :company
    belongs_to :network
    belongs_to :line_referential

    has_array_of :secondary_companies, class_name: 'Chouette::Company'

    has_many :routes, :dependent => :destroy
    has_many :journey_patterns, :through => :routes
    has_many :vehicle_journeys, :through => :journey_patterns
    has_many :routing_constraint_zones, through: :routes
    has_many :time_tables, -> { distinct }, :through => :vehicle_journeys

    has_and_belongs_to_many :group_of_lines, :class_name => 'Chouette::GroupOfLine', :order => 'group_of_lines.name'

    has_many :footnotes, :inverse_of => :line, :validate => :true, :dependent => :destroy
    accepts_nested_attributes_for :footnotes, :reject_if => :all_blank, :allow_destroy => true

    attr_reader :group_of_line_tokens

    # validates_presence_of :network
    # validates_presence_of :company

    # validates_format_of :registration_number, :with => %r{\A[\d\w_\-]+\Z}, :allow_nil => true, :allow_blank => true
    validates_format_of :stable_id, :with => %r{\A[\d\w_\-]+\Z}, :allow_nil => true, :allow_blank => true
    validates_format_of :url, :with => %r{\Ahttps?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\Z}, :allow_nil => true, :allow_blank => true

    validates_presence_of :name

    scope :by_text, ->(text) { where('lower(name) LIKE :t or lower(published_name) LIKE :t or lower(objectid) LIKE :t or lower(comment) LIKE :t or lower(number) LIKE :t',
      t: "%#{text.downcase}%") }

    scope :by_name, ->(name) {
      joins('LEFT OUTER JOIN public.companies ON companies.id = lines.company_id')
        .where('
          lines.number LIKE :q
          OR lines.name LIKE :q
          OR companies.name ILIKE :q',
          q: "%#{sanitize_sql_like(name)}%"
        )
    }

    scope :for_organisation, ->(organisation){
      if objectids = organisation&.lines_scope
        where(objectid: objectids)
      else
        all
      end
    }

    def self.nullable_attributes
      [:published_name, :number, :comment, :url, :color, :text_color, :stable_id]
    end

    def geometry_presenter
      Chouette::Geometry::LinePresenter.new self
    end

    def commercial_stop_areas
      Chouette::StopArea.joins(:children => [:stop_points => [:route => :line] ]).where(:lines => {:id => self.id}).uniq
    end

    def stop_areas
      Chouette::StopArea.joins(:stop_points => [:route => :line]).where(:lines => {:id => self.id})
    end

    def stop_areas_last_parents
      Chouette::StopArea.joins(:stop_points => [:route => :line]).where(:lines => {:id => self.id}).collect(&:root).flatten.uniq
    end

    def group_of_line_tokens=(ids)
      self.group_of_line_ids = ids.split(",")
    end

    def vehicle_journey_frequencies?
      self.vehicle_journeys.unscoped.where(journey_category: 1).count > 0
    end

    def display_name
      [self.get_objectid.short_id, number, name, company.try(:name)].compact.join(' - ')
    end

    def companies
      line_referential.companies.where(id: ([company_id] + Array(secondary_company_ids)).compact)
    end

    def deactivate
      self.deactivated = true
    end

    def activate
      self.deactivated = false
    end

    def deactivate!
      update_attribute :deactivated, true
    end

    def activate!
      update_attribute :deactivated, false
    end

    def activated?
      !deactivated
    end

    def status
      activated? ? :activated : :deactivated
    end
  end
end
