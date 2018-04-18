class AddFailedAtToReferentials < ActiveRecord::Migration
  def change
    add_column :referentials, :failed_at, :datetime
  end
end
