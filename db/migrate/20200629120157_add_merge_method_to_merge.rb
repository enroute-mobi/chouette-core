class AddMergeMethodToMerge < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :merges do |t|
        t.string :merge_method, default: 'legacy'
      end
    end
  end
end
