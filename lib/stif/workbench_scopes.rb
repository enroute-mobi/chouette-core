module Stif
  class WorkbenchScopes < ::WorkbenchScopes::All

    def lines_scope(initial_scope)
      ids = parse_functional_scope
      ids ? initial_scope.where(objectid: ids) : initial_scope.none
    end

    def stop_areas_scope(initial_scope)
      stop_areas_provider_objectids = parse_stop_areas_providers
      if stop_areas_provider_objectids
        ids = initial_scope.joins(:stop_area_providers).where("stop_area_providers.objectid" => stop_areas_provider_objectids).select('stop_areas.id').to_sql
        initial_scope.where("stop_areas.id IN (#{ids})")
      else
        initial_scope.none
      end
    end

    protected

    def parse_functional_scope
      return false unless @workbench.organisation.sso_attributes
      begin
        JSON.parse @workbench.organisation.sso_attributes['functional_scope']
      rescue Exception => e
        Rails.logger.error "WorkbenchScopes : #{e}"
      end
    end

    def parse_stop_areas_providers
      return false unless @workbench.organisation.sso_attributes
      begin
        # Sesame returns '77', when objectid is 'STIF-REFLEX:Operator:77'
        JSON.parse(@workbench.organisation.sso_attributes['stop_area_providers']).map do |local_id|
          "STIF-REFLEX:Operator:#{local_id}"
        end
      rescue Exception => e
        Rails.logger.error "WorkbenchScopes : #{e}"
      end
    end
  end
end
