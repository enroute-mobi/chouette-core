module Search
  class Workgroup < Base
    attribute :name

    def query(scope)
      Query::Workgroup.new(scope).name(name)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
