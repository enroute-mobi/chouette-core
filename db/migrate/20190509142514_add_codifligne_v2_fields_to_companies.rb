class AddCodifligneV2FieldsToCompanies < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      rename_column :companies, :organizational_unit, :default_contact_organizational_unit
      rename_column :companies, :operating_department_name, :default_contact_operating_department_name
      rename_column :companies, :email, :default_contact_email
      rename_column :companies, :phone, :default_contact_phone
      rename_column :companies, :fax, :default_contact_fax
      rename_column :companies, :url, :default_contact_url
      add_column :companies, :default_contact_name, :string
      add_column :companies, :default_contact_more, :text

      %w(private_contact customer_service_contact).each do |f|
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
