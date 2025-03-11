# frozen_string_literal: true

module Macro
  class CreateCodesFromParticulars < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :particular_code_space_id
        option :referent_code_space_id

        enumerize :target_model, in: %w[Line Company StopArea]

        validates :target_model, :particular_code_space_id, :referent_code_space_id, presence: true

        def particular_code_space
          @particular_code_space ||= workgroup.code_spaces.find_by(id: particular_code_space_id)
        end

        def referent_code_space
          @referent_code_space ||= workgroup.code_spaces.find_by(id: referent_code_space_id)
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        referents.find_each do |referent|
          code = referent.codes.create(code_space_id: referent_code_space_id, value: referent.particular_code_value)
          create_message(referent, code)
        end
      end

      def create_message(referent, code)
        attributes = {
          message_attributes: { referent_name: referent.name, code_value: code.value },
          source: referent
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless code.valid?

        macro_messages.create!(attributes)
      end

      def referents
        @referents ||= models.referents
                             .joins(:codes, particulars: :codes)
                             .select(
                                "public.#{model_collection}.*",
                                "codes_public_#{model_collection}.value AS particular_code_value"
                              )
                             .where('codes.code_space_id' => referent_code_space_id)
                             .where("codes_public_#{model_collection}.code_space_id" => particular_code_space_id)
                             .where("codes.value <> codes_public_#{model_collection}.value")
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end
    end
  end
end
