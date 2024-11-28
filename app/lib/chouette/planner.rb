# frozen_string_literal: true

module Chouette
  module Planner
    def self.create(from, to)
      Chouette::Planner::Base.new(from: from, to: to)
    end
  end
end
