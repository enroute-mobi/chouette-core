module Search
  class Workgroup < Base
    attr_accessor :workgroups

    attribute :name

    def query(scope)
      Query::Workgroup.new(scope).name(name)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
