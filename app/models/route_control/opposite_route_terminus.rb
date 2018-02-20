module RouteControl
  class OppositeRouteTerminus < ComplianceControl

    def self.default_code; "3-Route-5" end

    def prerequisite; I18n.t("compliance_controls.#{self.class.name.underscore}.prerequisite") end     
  end
end
