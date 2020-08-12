module Types
	class PrettyJSON < Types::BaseScalar
		description "An untyped JSON scalar that removes empty keys for a nicer display"

		def self.coerce_input(value, _context)
        value
      end

      def self.coerce_result(value, _context)
        value.delete_if { |k, v| v.empty? }
      end
	end
end