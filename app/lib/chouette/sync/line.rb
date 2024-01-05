module Chouette::Sync
  module Line
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :line,
          resource_id_attribute: :id,
          model_type: :line,
          resource_decorator: Decorator
        }
        options.reverse_merge!(default_options)
        super options
      end

      def imported_line_ids
        updater.target.lines.where(registration_number: processed_identifiers).pluck(:id)
      end

      class Decorator < Chouette::Sync::Netex::Decorator
        def line_number
          short_name
        end

        def line_desactivated
          status == "inactive"
        end

        TYPE_OF_LINE_SEASONAL = "SEASONAL_LINE_TYPE"
        def line_seasonal
          type_of_line_ref&.ref == TYPE_OF_LINE_SEASONAL
        end

        def line_active_from
          valid_between&.from_date
        end

        def line_active_until
          valid_between&.to_date
        end

        def line_color
          presentation&.colour&.upcase
        end

        def line_text_color
          presentation&.text_colour&.upcase
        end

        def line_company_id
          resolve :company, operator_ref&.ref
        end

        def line_secondary_company_refs
          return [] if additional_operators.blank?
          # Ignore main operator in additional operators
          additional_operators.map(&:ref) - [operator_ref&.ref]
        end

        def line_secondary_company_ids
          resolve :company, line_secondary_company_refs
        end

        def line_network_id
          resolve :network, represented_by_group_ref&.ref
        end

        def line_notice_refs
          return [] unless notice_assignments
          notice_assignments.map do |notice_assignment|
            notice_assignment&.notice_ref&.ref
          end
        end

        def line_notice_ids
          resolve :line_notice, line_notice_refs
        end

        def line_transport_submode
          transport_submode
        end

        def model_attributes
          {
            name: name,
            transport_mode: transport_mode,
            transport_submode: line_transport_submode,
            number: line_number,
            desactivated: line_desactivated,
            seasonal: line_seasonal,
            active_from: line_active_from,
            active_until: line_active_until,
            color: line_color,
            text_color: line_text_color,
            company_id: line_company_id,
            secondary_company_ids: line_secondary_company_ids,
            network_id: line_network_id,
            line_notice_ids: line_notice_ids,
            mobility_impaired_accessibility: accessibility.mobility_impaired_access,
            wheelchair_accessibility: accessibility.wheelchair_access,
            step_free_accessibility: accessibility.step_free_access,
            escalator_free_accessibility: accessibility.escalator_free_access,
            lift_free_accessibility: accessibility.lift_free_access,
            audible_signals_availability: accessibility.audible_signals_available,
            visual_signs_availability: accessibility.visual_signs_available,
            accessibility_limitation_description: accessibility.description,
            import_xml: raw_xml
          }
        end
      end
    end

    class Deleter < Chouette::Sync::Deleter

      def existing_models(identifiers = nil)
        super(identifiers).activated
      end

      def delete_all(deleted_scope)
        deleted_scope.desactivate!
      end

    end

  end
end
