require 'range_ext'

class Calendar < ApplicationModel
  include DateSupport
  include PeriodSupport
  include ApplicationDaysSupport
  include TimetableSupport

  has_metadata
  belongs_to :workbench # CHOUETTE-3247 required: true
  has_one :organisation, through: :workbench
  has_one :workgroup, through: :workbench

  validates :name, presence: true

  has_many :time_tables, class_name: 'Chouette::TimeTable' # rubocop:disable Rails/HasManyOrHasOneDependent

  scope :contains_date, ->(date) { where('(date ? = any (dates) OR date ? <@ any (date_ranges)) AND NOT date ? = any (excluded_dates)', date, date, date) }

  scope :order_by_organisation_name, ->(dir) { joins(:organisation).order("lower(organisations.name) #{dir}") }

  scope :by_text, ->(text) { text.blank? ? all : where('lower(name) LIKE :t', t: "%#{text.downcase}%") }

  after_initialize :set_defaults

  def self.ransackable_scopes(auth_object = nil)
    [:contains_date]
  end

  def self.state_permited_attributes item
    item.slice('shared').tap do |h|
      h['name'] = item['comment'] if item.key?('comment')
    end
  end

  def set_defaults
    self.excluded_dates ||= []
    self.int_day_types ||= EVERYDAY
  end

  def human_attribute_name(*args)
    self.class.human_attribute_name(*args)
  end

  def shortcuts_update(date=nil)
  end

  def convert_to_time_table(comment = nil)
    Chouette::TimeTable.new.tap do |tt|
      self.excluded_dates.each do |d|
        tt.dates << Chouette::TimeTableDate.new(date: d, in_out: false)
      end
      self.dates.each do |d|
        tt.dates << Chouette::TimeTableDate.new(date: d, in_out: true)
      end
      self.periods.each do |p|
        tt.periods << Chouette::TimeTablePeriod.new(period_start: p.begin, period_end: p.end)
      end
      tt.int_day_types = self.int_day_types
      tt.comment = comment
      tt.calendar = self
    end
  end

  def include_in_dates?(day)
    self.dates.include? day
  end

  def excluded_date?(day)
    self.excluded_dates.include? day
  end

  def update_in_out date, in_out
    if in_out
      self.excluded_dates.delete date
      self.dates << date unless include_in_dates?(date)
    else
      self.dates.delete date
      self.excluded_dates << date unless excluded_date?(date)
    end
    date
  end

  def every_dates
    dates + excluded_dates
  end

  def saved_dates
    Hash[*every_dates.each_with_index.to_a.map(&:reverse).flatten]
  end

  def all_dates
    every_dates.sort.each_with_index.map do |d, i|
      OpenStruct.new(id: i, date: d, in_out: include_in_dates?(d))
    end
  end

  def find_date_by_id id
    every_dates[id]
  end

  def build_date in_out, date
    update_in_out date, in_out
  end

  def find_period_by_id id
    self.periods.find { |p| p.id == id }
  end

  def build_period
    self.periods << Calendar::Period.new(id: self.periods.count + 1)
    self.periods.last
  end

  def delete_periods deleted_periods
    self.periods.delete_if{ |period|
      deleted_periods.each do |deleted_period|
        deleted_period.begin == period.begin && deleted_period.end == period.end
      end
    }
  end
end
