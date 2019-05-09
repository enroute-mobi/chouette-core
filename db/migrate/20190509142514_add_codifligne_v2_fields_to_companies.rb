class AddCodifligneV2FieldsToCompanies < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      %w(default_contact private_contact customer_service_contact).each do |f|
        %w(name email phone url).each do |attr|
          add_column :companies, "#{f}_#{attr}", :string
        end
        add_column :companies, "#{f}_more", :text
      end
      add_column :companies, :house_number, :string
      add_column :companies, :address_line_1, :string
      add_column :companies, :address_line_2, :string
      add_column :companies, :street, :string
      add_column :companies, :town, :string
      add_column :companies, :postcode, :string
      add_column :companies, :postcode_extension, :string
    end
  end
end
