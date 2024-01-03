module TableBuilderHelper
  class URL
    def self.polymorphic_url_parts(item, referential, workgroup)
      polymorph_url = []

      unless item.is_a?(Calendar) || item.is_a?(Referential)
        if referential
          polymorph_url << referential
          polymorph_url << item.line if item.respond_to? :line
          polymorph_url << item.route.line if item.is_a?(Chouette::RoutingConstraintZone)
          polymorph_url << item if item.respond_to? :line_referential
          polymorph_url << item.stop_area if item.respond_to? :stop_area
          polymorph_url << item if item.respond_to?(:stop_points) || item.is_a?(Chouette::TimeTable)
        elsif item.respond_to? :referential
          if item.respond_to? :workbench
            polymorph_url << item.workbench
            polymorph_url << item
          else
            polymorph_url << item.referential
          end
        end
      else
        polymorph_url << item.workgroup if item.respond_to? :workgroup
        polymorph_url << item
      end

      polymorph_url
    end
  end
end
