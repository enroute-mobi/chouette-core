import { Path } from 'path-parser'

const routeMatch = path => !!Path.createPath(path).test(location.pathname)
class FileRouter {
	static async init() {
		switch (true) {
			// Calendars
			case routeMatch('/workgroups/:workgroupId/calendars/:id/edit'):
				return await import('./calendars/edit')

			// Compliance Control Blocks
			case routeMatch('/compliance_control_sets/:ccSetId/compliance_control_blocks/new'):
			case routeMatch('/compliance_control_sets/:ccSetId/compliance_control_blocks/:id/edit'):
				return await import('./compliance_control_blocks/form')

			// Connections Links
			case routeMatch('/workbenches/:workbenchId/stop_area_referential/connection_links/new'):
			case routeMatch('/workbenches/:workbenchId/stop_area_referential/connection_links/:id/edit'):
				return await import('./connection_links/form')
			case routeMatch('/workbenches/:workbenchId/stop_area_referential/connection_links/:id'):
				return await import('./connection_links/show')

			// Entrances
			case routeMatch('/workbenches/:workbenchId/stop_area_referential/entrances/:id'):
				return await import('./entrances/show')

			// Exports
			case routeMatch('/workbenches/:workbenchId/exports/new'):
			case routeMatch('/workbenches/:workbenchId/exports/:id/edit'):
				return await import('./exports/form')
			case routeMatch('/workbenches/:workbenchId/exports'):
				return await import('./inputs/date_picker')
			case routeMatch('/workgroups/:workbenchId/exports'):
				return await import('./inputs/date_picker')

			// Imports
			case routeMatch('/workbenches/:workbenchId/imports/new'):
			case routeMatch('/workbenches/:workbenchId/imports/:id/edit'):
				return await import('./imports/form')
			case routeMatch('/workbenches/:workbenchId/imports'):
				return await import('./inputs/date_picker')
			case routeMatch('/workgroups/:workbenchId/imports'):
				return await import('./inputs/date_picker')

			// Journey Patterns
			case routeMatch('/referentials/:referentialId/lines/:lineId/routes/:routeId/journey_patterns_collection'):
				return await import('./journey_patterns')

			// Line Notices
			case routeMatch('/workbenches/:workbenchId/line_referential/lines/:lineId/line_notices/attach'):
				return await import('./line_notices/attach')

			// Lines
			case routeMatch('/workbenches/:workbenchId/line_referential/lines/new'):
			case routeMatch('/workbenches/:workbenchId/line_referential/lines/:id/edit'):
				return await import('./lines/form')
			case routeMatch('/workbenches/:workbenchId/line_referential/lines'):
				return await import('./lines/index')

			// Macro Lits
			case routeMatch('/workbenches/:workbenchId/macro_lists/new'):
				return await import('./macro_lists/form')
	
			// Merges
			case routeMatch('/workbenches/:workbenchId/merges/new'):
				return await import('./merges/new')
			
			// Notifications Rules
			case routeMatch('/workbenches/:workbenchId/notification_rules/new'):
			case routeMatch('/workbenches/:workbenchId/notification_rules/:id/edit'):
				return await import('./inputs/date_picker')
			case routeMatch('/workbenches/:workbenchId/notification_rules'):
				return await import('./inputs/date_picker')

			// Publications APIs
			case routeMatch('/workgroups/:workgroupId/publication_apis/new'):
			case routeMatch('/workgroups/:workgroupId/publication_apis/:id/edit'):
				return await import('./publication_apis/form')

			// Publications Setups
			case routeMatch('/workgroups/:workgroupId/publication_setups/new'):
			case routeMatch('/workgroups/:workgroupId/publication_setups/:id/edit'):
				return await Promise.all([
					import('./exports/form'),
					import('./publication_setups/form')
				])

			// Referentials
			case routeMatch('/referentials/:id'):
				return await import('./referential_overview/index')

			// Referential Lines
			case routeMatch('/referentials/:referentialId/lines/:id'):
				return await import('./referential_lines/show')

			// Routes
			case routeMatch('/referentials/:referentialId/lines/:lineId/routes/new'):
			case routeMatch('/referentials/:referentialId/lines/:lineId/routes/:routeId/edit'):
				return await import('./routes/form')
			case routeMatch('/referentials/:referentialId/lines/:lineId/routes/:routeId'):
				return await import('./routes/show')

			// Shapes
			case routeMatch('/referentials/:referentialId/lines/:lineId/routes/:routeId/journey_patterns/:journeyPatternId/shapes/new'):
			case routeMatch('/referentials/:referentialId/lines/:lineId/routes/:routeId/journey_patterns/:journeyPatternId/shapes/edit'):
				return await import('./shapes/form')
			case routeMatch('/workbenches/:workbenchId/shape_referential/shapes/:id'):
				return await import('./shapes/show')
			case routeMatch('/workbenches/:workbenchId/shape_referential/shapes'):
				return await import('./shapes/index')

			// Stop Areas
			case routeMatch('/workbenches/:workbenchId/stop_area_referential/stop_areas/new'):
			case routeMatch('/workbenches/:workbenchId/stop_area_referential/stop_areas/:id/edit'):
				return await import('./stop_areas/form')
			case routeMatch('/workbenches/:workbenchId/stop_area_referential/stop_areas/:id'):
				return await import('./stop_areas/show')

			// Timetables
			case routeMatch('/referentials/:referentialId/time_tables/:id/edit'):
				return await import('./time_tables/edit')

			// Users
			case routeMatch('/organisation/users/new_invitation'):
			case routeMatch('/organisation/users/:id/edit'):
				return await import('./user_invitations/new')

			// Vehicle Journeys
			case routeMatch('/referentials/:referentialId/lines/:lineId/routes/:routeId/vehicle_journeys'):
				return await import('./vehicle_journeys/index')

			// Workgroups
			case routeMatch('/workgroups/:workgroupId/edit_aggregate'):
				return await Promise.all([
					import('./workgroups/edit_aggregate'),
					import('./inputs/date_picker'),
				])
			case routeMatch('/workgroups/:workgroupId/edit_merge'):
				return await import('./workgroups/edit_merge')
			case routeMatch('/workgroups/:workgroupId/edit_transport_modes'):
				return await import('./workgroups/edit_transport_modes')

		}
	}
}

FileRouter.init()
