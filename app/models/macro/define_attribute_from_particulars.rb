# frozen_string_literal: true
module Macro
  class DefineAttributeFromParticulars < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute

        enumerize :target_model, in: %w[StopArea Company]

        validates :target_model, :target_attribute, :model_attribute, presence: true
      end

      def model_attribute
        candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
      end

      def candidate_target_attributes # rubocop:disable Metrics/MethodLength
        Chouette::ModelAttribute.collection do

          # Chouette::Company
          select Chouette::Company, :short_name
          select Chouette::Company, :code
          select Chouette::Company, :customer_service_contact_email
          select Chouette::Company, :customer_service_contact_more
          select Chouette::Company, :customer_service_contact_name
          select Chouette::Company, :customer_service_contact_phone
          select Chouette::Company, :customer_service_contact_url
          select Chouette::Company, :default_contact_email
          select Chouette::Company, :default_contact_fax
          select Chouette::Company, :default_contact_more
          select Chouette::Company, :default_contact_name
          select Chouette::Company, :default_contact_operating_department_name
          select Chouette::Company, :default_contact_organizational_unit
          select Chouette::Company, :default_contact_phone
          select Chouette::Company, :default_contact_url
          select Chouette::Company, :default_language
          select Chouette::Company, :private_contact_email
          select Chouette::Company, :private_contact_more
          select Chouette::Company, :private_contact_name
          select Chouette::Company, :private_contact_phone
          select Chouette::Company, :private_contact_url
          select Chouette::Company, :address_line_1
          select Chouette::Company, :address_line_2
          select Chouette::Company, :country_code
          select Chouette::Company, :house_number
          select Chouette::Company, :postcode
          select Chouette::Company, :postcode_extension
          select Chouette::Company, :street
          select Chouette::Company, :time_zone
          select Chouette::Company, :town

          # Chouette::StopArea
          select Chouette::StopArea, :fare_code
          select Chouette::StopArea, :country_code
          select Chouette::StopArea, :street_name
          select Chouette::StopArea, :zip_code
          select Chouette::StopArea, :city_name
          select Chouette::StopArea, :url
          select Chouette::StopArea, :time_zone
          select Chouette::StopArea, :waiting_time
          select Chouette::StopArea, :postal_region
          select Chouette::StopArea, :public_code
          select Chouette::StopArea, :accessibility_limitation_description
          select Chouette::StopArea, :escalator_free_accessibility
          select Chouette::StopArea, :lift_free_accessibility
          select Chouette::StopArea, :mobility_impaired_accessibility
          select Chouette::StopArea, :step_free_accessibility
          select Chouette::StopArea, :wheelchair_accessibility
          select Chouette::StopArea, :visual_signs_availability
          select Chouette::StopArea, :audible_signals_availability
          select Chouette::StopArea, :lines
          select Chouette::StopArea, :routes
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        referents_with_value.find_each do |referent|
          value = particular_values[referent.id]

          referent.update(attribute_name => value)
          create_message referent, attribute_name
        end
      end

      def create_message(referent, attribute_name)
        attribute_value = referent.send(attribute_name)

        # When value is an enumerize value
        attribute_value = attribute_value.text if attribute_value.respond_to?(:text)

        attributes = {
          message_attributes: {
            name: referent.name, attribute_name:
            referent.class.human_attribute_name(attribute_name),
            attribute_value: attribute_value
          },
          source: referent
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless referent.valid?

        macro_messages.create!(attributes)
      end

      # Retrieve referents without target attribute in the macro scope
      def referents
        @referents ||= models.referents.where(attribute_name => undefined_value)
      end

      def undefined_value
        # For example Chouette::StopArea.wheelchair_accessibility.default_value => "unknown"
        # or nil ...
        model_attribute.model_class.try(attribute_name).try(:default_value)
      end

      # Retrieve all particulars associated to the referents (so in the whole scope)
      def particulars
        @particulars ||= macro_list_run.base_scope
                                       .send(model_collection)
                                       .particulars.where(referent: referents)
                                       .where.not(attribute_name => nil)
      end

      # Load (in memry :-/) only common value for particulars with the same referent
      def particular_values
        @particular_values ||= begin
          values = particulars.group(:referent_id)
                              .select(:referent_id, "array_agg(DISTINCT #{model_table}.#{attribute_column}) as values")

          # Uses a subquery to reject multiple values
          query = <<~SQL
            select referent_id_and_values.referent_id, referent_id_and_values.values[1]
            from (#{values.to_sql}) as referent_id_and_values
            where array_length(referent_id_and_values.values, 1) = 1;
          SQL

          Hash[ActiveRecord::Base.connection.select_rows(query)]
        end
      end

      def referents_with_value_ids
        particular_values.keys
      end

      # Referents with have a common value found
      def referents_with_value
        referents.where(id: referents_with_value_ids)
      end

      # "stop_areas", "companies", etc
      def model_collection
        @model_collection ||= model_attribute.model_class.model_name.plural
      end

      # "public.stop_areas", "public.companies", etc
      def model_table
        model_attribute.model_class.table_name
      end

      # "name", "waiting_time", etc
      def attribute_name
        model_attribute.name
      end

      # "name", "waiting_time", etc
      def attribute_column
        # TODO: should be smarter
        model_attribute.name
      end

      # stop_areas, companies, etc (which could be modified)
      def models
        @models ||= scope.send(model_collection)
      end

    end
  end
end
