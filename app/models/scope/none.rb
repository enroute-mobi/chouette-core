# frozen_string_literal: true

module Scope
  class None < Base
    def scopes?(name)
      !active_record(name).nil?
    end

    def collection(name, **)
      active_record(name).none
    end

    private

    def active_record(name)
      const_name = name.to_s.classify
      const = if Chouette.const_defined?(const_name)
                Chouette.const_get(const_name)
              elsif Object.const_defined?(const_name)
                Object.const_get(const_name)
              end
      return nil unless const && const < ActiveRecord::Base

      const
    end
  end
end
