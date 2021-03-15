module Exports
	class FormFacade
		attr_reader :workbench

		def initialize(workbench)
			@workbench = workbench
		end

		def exported_lines_types_options
			[
				['Specific Lines', 'line'],
				['Company Set', 'company'],
				['Line Provider Set', 'line_provider'],
			]
		end

		def lines_options
			workbench.lines
		end

		def companies_options
			workbench.companies.map { |c| [c.name, c.line_ids] }
		end

		def line_providers_options
			workbench.line_providers.map { |lp| [lp.short_name, lp.line_ids] }
		end
	end
end
