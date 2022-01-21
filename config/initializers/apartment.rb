# Require whichever elevator you're using below here...
#
# require 'apartment/elevators/generic'
# require 'apartment/elevators/domain'
# require 'apartment/elevators/subdomain'

#
# Apartment Configuration
#
Apartment.configure do |config|

  # These models will not be multi-tenanted,
  # but remain in the global (public) namespace
  #
  # An example might be a Customer or Tenant model that stores each tenant information
  # ex:
  #
  # config.excluded_models = %w{Tenant}
  #
  config.excluded_models = [
    'Aggregate',
    'ApiKey',
    'Calendar',
    'Chouette::LineNoticeMembership',
    'Chouette::Company',
    'Chouette::Network',
    'Chouette::ConnectionLink',
    'Chouette::GroupOfLineMembership',
    'Chouette::GroupOfLine',
    'Chouette::Line',
    'Chouette::LineNotice',
    'Chouette::StopArea',
    'CleanUp',
    'CleanUpResult',
    'Code',
    'CodeSpace',
    'ComplianceCheckMessage',
    'ComplianceCheck',
    'ComplianceCheckBlock',
    'ComplianceCheckResource',
    'ComplianceCheckSet',
    'ComplianceControl',
    'ComplianceControlBlock',
    'ComplianceControlSet',
    'CrossReferentialIndexEntry',
    'CustomField',
    'Delayed::Heartbeat::Worker',
    'Delayed::Job',
    'Destination',
    'DestinationReport',
    'Entrance',
    'Export::Base',
    'Export::Message',
    'Export::Resource',
    # 'GenericAttributeControl::MinMax',
    'GenericAttributeControl::Pattern',
    'GenericAttributeControl::Uniqueness',
    'GenericAttributeControl::Presence',
    'Import::Base',
    'Import::Gtfs',
    'Import::Message',
    'Import::Netex',
    'Import::Resource',
    'Import::Workbench',
    'JourneyPatternControl::Duplicates',
    'JourneyPatternControl::VehicleJourney',
    'LineProvider',
    'LineControl::Route',
    'LineReferential',
    'LineReferentialMembership',
    'LineReferentialSync',
    'LineReferentialSyncMessage',
    'LineRoutingConstraintZone',
    'Merge',
    'Macro::Base',
    'Macro::Base::Run',
    'Macro::List',
    'Macro::List::Run',
    'Macro::Message',
    'Macro::Context',
    'Macro::Context::Run',
    'Notification',
    'NotificationRule',
    'Organisation',
    'Publication',
    'PublicationApi',
    'PublicationApiKey',
    'PublicationApiSource',
    'PublicationSetup',
    'RawImport',
    'Referential',
    'ReferentialCloning',
    'ReferentialMetadata',
    'ReferentialSuite',
    'RouteControl::Duplicates',
    'RouteControl::JourneyPattern',
    'RouteControl::MinimumLength',
    'RouteControl::OmnibusJourneyPattern',
    'RouteControl::OppositeRoute',
    'RouteControl::OppositeRouteTerminus',
    'RouteControl::StopPointsInJourneyPattern',
    'RouteControl::UnactivatedStopPoint',
    'RouteControl::ZDLStopArea',
    'RoutingConstraintZoneControl::MaximumLength',
    'RoutingConstraintZoneControl::MinimumLength',
    'RoutingConstraintZoneControl::UnactivatedStopPoint',
    'Shape',
    'ShapeProvider',
    'ShapeReferential',
    'StopAreaProvider',
    'StopAreaReferential',
    'StopAreaReferentialMembership',
    'StopAreaReferentialSync',
    'StopAreaReferentialSyncMessage',
    'StopAreaRoutingConstraint',
    'Source',
    'User',
    'VehicleJourneyControl::Delta',
    'VehicleJourneyControl::Speed',
    'VehicleJourneyControl::TimeTable',
    'VehicleJourneyControl::VehicleJourneyAtStops',
    'VehicleJourneyControl::WaitingTime',
    'Waypoint',
    'Workbench',
    'Workgroup',
  ]

  # use postgres schemas?
  config.use_schemas = true

  # use raw SQL dumps for creating postgres schemas? (only appies with use_schemas set to true)
  #config.use_sql = true

  # configure persistent schemas (E.g. hstore )
  config.persistent_schemas = %w{ shared_extensions }

  # add the Rails environment to database names?
  # config.prepend_environment = true
  # config.append_environment = true

  # supply list of database names for migrations to run on
  config.tenant_names = lambda{  Referential.where(ready: true).order("created_from_id asc").pluck(:slug) }
end

##
# Elevator Configuration

# Rails.application.config.middleware.use 'Apartment::Elevators::Generic', lambda { |request|
#   # TODO: supply generic implementation
# }

# Rails.application.config.middleware.use 'Apartment::Elevators::Domain'

# Rails.application.config.middleware.use 'Apartment::Elevators::Subdomain'
