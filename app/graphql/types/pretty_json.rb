module Types
  class PrettyJson < Types::BaseScalar
    description "An untyped JSON scalar that removes empty keys for a nicer display"

    def self.coerce_input(value, _context)
        value
      end

      def self.coerce_result(value, _context)
        value.delete_if { |_, v| v.empty? }
      end
  end
end
