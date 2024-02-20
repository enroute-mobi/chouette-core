# frozen_string_literal: true

class UpdateEmptyStringsOfEntrancesAndPointOfInterestsAddressesColumnsToNull < ActiveRecord::Migration[5.2]
  def up
    attributes = %w[country city_name zip_code address_line_1]
    update_set = attributes.map { |a| "#{a} = NULLIF(#{a}, '')" }.join(', ')
    update_where = attributes.map { |a| "#{a} = ''" }.join(' OR ')

    on_public_schema_only do
      execute(%(UPDATE "entrances" SET #{update_set} WHERE #{update_where}))
      execute(%(UPDATE "point_of_interests" SET #{update_set} WHERE #{update_where}))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
