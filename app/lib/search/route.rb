module Search
  class Route < Base
    # All search attributes
    attribute :text
    attribute :wayback

    enumerize :wayback, in: ::Chouette::Route.wayback.values, i18n_scope: 'enumerize.route.wayback'

    attr_accessor :workbench

    def query(scope)
      Query::Route.new(scope)
                    .text(text)
                    .wayback(wayback)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :wayback
    end
  end
end
