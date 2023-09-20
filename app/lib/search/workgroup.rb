module Search
  class Workgroup < Base
    attr_accessor :workgroups

    attribute :name
    attribute :owner_id

    def candidate_owners
      workgroups.map{|w| w.owner }.sort_by(&:name)
    end

    def owner
      candidate_owners.find{|owner| owner.id == owner_id}
    end

    def query(scope)
      Query::Workgroup.new(scope).name(name).owner(owner)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
