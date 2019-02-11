class Chouette::Netex::Operator
  include Chouette::Netex::Helpers

  attr_accessor :company

  def initialize(company)
    @company = company
  end

  def custom_field_values
    company.custom_fields.values.select{ |v| v.display_value.present? }.map do |v|
      [v.code, v.display_value]
    end
  end

  def attributes
    {
      'PublicCode'  => 'code',
      'CompanyCode' => 'registration_number',
      'Name'        => 'name',
      'ShortName'   => 'short_name'
    }
  end

  def contact_attributes
    {
      'Email' => 'email',
      'Phone' => 'phone',
      'Url'   => 'url'
    }
  end

  def to_xml(builder)
    builder.Operator(
      version: :any,
      created: format_time(company.created_at),
      changed: format_time(company.updated_at),
      id: company.objectid) do
      builder.keyList do
        custom_field_values.each do |k, v|
          builder.KeyValue do
            builder.Key k
            builder.Value v
          end
        end
      end

      attributes.each do |tag, attr|
        builder.send(tag, company.send(attr))
      end

      builder.ContactDetails do
        contact_attributes.each do |tag, attr|
          builder.send(tag, company.send(attr))
        end
      end
    end
  end
end
