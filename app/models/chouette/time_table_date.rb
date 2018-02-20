module Chouette
  class TimeTableDate < Chouette::ActiveRecord
    include ChecksumSupport

    self.primary_key = "id"
    belongs_to :time_table, inverse_of: :dates
    acts_as_list :scope => 'time_table_id = #{time_table_id}',:top_of_list => 0

    validates_presence_of :date
    validates_uniqueness_of :date, :scope => :time_table_id

    scope :in_dates, -> { where(in_out: true) }

    def self.model_name
      ActiveModel::Name.new Chouette::TimeTableDate, Chouette, "TimeTableDate"
    end

    def checksum_attributes
      attrs = ['date', 'in_out']
      self.slice(*attrs).values
    end
  end
end
