class ConvertJourneyPatternsCosts < ActiveRecord::Migration[5.2]
  def change
    # costs = {"16471-16472"=>{"time"=>300, "distance"=>11800},
    #          "16472-16470"=>{"time"=>300, "distance"=>46364},
    #          "16473-16471"=>{"time"=>300, "distance"=>230},
    #          "16474-16473"=>{"time"=>300, "distance"=>10}}
    Chouette::JourneyPattern.where.not(costs: {}).find_each do |journey_pattern|
      journey_pattern.costs = journey_pattern.costs.transform_values do |link_costs|
        link_costs.map do |type, value|
          [type, convert(type, value)]
        end.to_h
      end

      journey_pattern.update_checksum if journey_pattern.checksum
      journey_pattern.save!
    end
  end

  def convert(type, value)
    case type
    when 'time'
      value * 60
    when 'distance'
      value * 1000
    else
      value
    end
  end
end
