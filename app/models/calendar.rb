require 'range_ext'
require_relative 'calendar/date_value'
require_relative 'calendar/period'

class Calendar < ActiveRecord::Base
  include DateSupport
  include PeriodSupport
  include ApplicationDaysSupport
  include TimetableSupport

  has_paper_trail class_name: 'PublicVersion'
  belongs_to :organisation
  belongs_to :workgroup

  validates_presence_of :name, :organisation, :workgroup

  has_many :time_tables

  scope :contains_date, ->(date) { where('date ? = any (dates) OR date ? <@ any (date_ranges)', date, date) }

  after_initialize :set_defaults

  def self.ransackable_scopes(auth_object = nil)
    [:contains_date]
  end

  def self.state_permited_attributes item
    {name: item["comment"]}
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

  def convert_to_time_table
    Chouette::TimeTable.new.tap do |tt|
      self.dates.each do |d|
        tt.dates << Chouette::TimeTableDate.new(date: d, in_out: true)
      end
      self.periods.each do |p|
        tt.periods << Chouette::TimeTablePeriod.new(period_start: p.begin, period_end: p.end)
      end
      tt.int_day_types = self.int_day_types
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

  def included_days
    dates
  end

  def excluded_days
    excluded_dates
  end

  def saved_dates
    Hash[*self.dates.each_with_index.to_a.map(&:reverse).flatten]
  end

  def all_dates
    (dates + excluded_dates).sort.each_with_index.map do |d, i|
      OpenStruct.new(id: i, date: d, in_out: include_in_dates?(d))
    end
  end

  def find_date_by_id id
    self.dates[id]
  end

  def destroy_date date
    self.dates -= [date]
  end

  def create_date in_out:, date:
    update_in_out date, in_out
  end

  def find_period_by_id id
    self.periods.find{|p| p.id == id}
  end

  def build_period
    self.periods << Calendar::Period.new(id: self.periods.count + 1)
    self.periods.last
  end

  def destroy_period period
    @periods = self.periods.select{|p| p.end != period.end || p.begin != period.begin}
  end
end
