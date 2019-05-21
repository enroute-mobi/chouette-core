class ChangeReferentAreaType < ActiveRecord::Migration[5.2]
  def up
  	say_with_time "Updating StopArea#area_type" do
  		count = 0
  		Chouette::StopArea.where(area_type: 'zder').find_each do |stop_area|
  			stop_area.update area_type: 'zdep', is_referent: true
  			count += 1
  		end
  		Chouette::StopArea.where(area_type: 'zdlr').find_each do |stop_area|
  			stop_area.update area_type: 'zdlp', is_referent: true
  			count += 1
  		end
  		count
  	end
  end
end
