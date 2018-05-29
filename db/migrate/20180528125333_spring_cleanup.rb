class SpringCleanup < ActiveRecord::Migration
  def change
    [:journey_frequencies, :timebands].each do |t|
      drop_table t
    end
  end
end
