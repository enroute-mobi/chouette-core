# frozen_string_literal: true

module Stif
  class WorkbenchScopes < ::WorkbenchScopes::All
    def lines_scope(initial_scope)
      line_object_ids = parse_functional_scope
      return initial_scope.none unless line_object_ids

      initial_scope.where(objectid: line_object_ids)
    end

    def stop_areas_scope(initial_scope)
      stop_areas_provider_objectids = parse_stop_areas_providers
      return initial_scope.none unless stop_areas_provider_objectids

      ids = initial_scope.joins(:stop_area_provider)
                         .where(::StopAreaProvider.quoted_table_name => { objectid: stop_areas_provider_objectids })
                         .select('stop_areas.id')
                         .to_sql
      initial_scope.where("stop_areas.id IN (#{ids})")
    end

    def referentials_scope(initial_scope)
      if allowed_line_ids.empty?
        Referential.none
      else
        Referential.where(id: initial_scope.include_metadatas_lines(allowed_line_ids).select(:id).distinct)
      end
    end

    protected

    def allowed_line_ids
      @allowed_line_ids ||= workbench.line_ids
    end

    def sso_attributes
      @sso_attributes ||= workbench.organisation.sso_attributes
    end

    def parse_functional_scope
      return nil unless sso_attributes

      begin
        @functional_scope ||= JSON.parse(sso_attributes['functional_scope'])
      rescue StandardError => e
        ::Chouette::Safe.capture('WorkbenchScopes functional_scope failed', e)
        nil
      end
    end

    def parse_stop_areas_providers
      return nil unless sso_attributes

      begin
        # Sesame returns '77', when objectid is 'FR1:OrganisationalUnit:77:'
        @stop_areas_providers ||= JSON.parse(sso_attributes['stop_area_providers']).map do |local_id|
          "FR1:OrganisationalUnit:#{local_id}:"
        end
      rescue StandardError => e
        ::Chouette::Safe.capture('WorkbenchScopes stop_areas_providers failed', e)
        nil
      end
    end
  end
end
