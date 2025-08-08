# frozen_string_literal: true

module Search
  class User < Base
    # All search attributes
    attribute :text
    attribute :profile
    attribute :state

    attr_accessor :organisation

    def searched_class
      ::User
    end

    def query(scope)
      Query::User.new(scope) \
                 .text(text) \
                 .profile(profile) \
                 .state(state)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :email
    end
  end
end
