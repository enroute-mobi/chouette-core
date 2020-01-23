class Chouette::Netex::DayType < Chouette::Netex::Resource
  def self.application_days
    get_cache(:application_days) || {}
  end

  def build_cache(int_day_types)
    application_days = self.class.application_days
    application_days[int_day_types] = Chouette::TimeTable::ALL_DAYS.select{ |d| resource.send(d) }.map(&:capitalize).join(' ')
    self.class.set_cache :application_days, application_days
  end

  def application_days(int_day_types)
    self.class.application_days[int_day_types] || build_cache(int_day_types) && self.class.application_days[int_day_types]
  end

  def attributes
    { 'Name' => :comment }
  end

  def days_of_week
    application_days resource.int_day_types
  end

  def build_xml
    @builder.DayType(resource_metas) do
      node_if_content 'keyList' do
        key_value 'Tags', (resource.tags&.sort_by(&:name) || []).join(',')
        key_value 'Colour', resource.color
      end
      attributes_mapping
      @builder.properties do
        @builder.PropertyOfDay do
          @builder.DaysOfWeek days_of_week
        end
      end
    end
  end
end
