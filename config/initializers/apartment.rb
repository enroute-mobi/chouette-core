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
    'Referential',
    'ReferentialMetadata',
    'ReferentialSuite',
    'Organisation',
    'User',
    'Api::V1::ApiKey',
    'StopAreaReferential',
    'StopAreaReferentialMembership',
    'StopAreaReferentialSync',
    'StopAreaReferentialSyncMessage',
    'Chouette::StopArea',
    'LineReferential',
    'LineReferentialMembership',
    'LineReferentialSync',
    'LineReferentialSyncMessage',
    'Chouette::Line',
    'Chouette::GroupOfLine',
    'Chouette::Company',
    'Chouette::Network',
    'ReferentialCloning',
    'Workbench',
    'Workgroup',
    'CleanUp',
    'CleanUpResult',
    'Calendar',
    'Import',
    'NetexImport',
    'WorkbenchImport',
    'ImportMessage',
    'ImportResource',
    'ComplianceControl',
    'GenericAttributeControl::MinMax',
    'GenericAttributeControl::Pattern',
    'GenericAttributeControl::Uniqueness',
    'JourneyPatternControl::Duplicates',
    'JourneyPatternControl::VehicleJourney',
    'LineControl::Route',
    'RouteControl::Duplicates',
    'RouteControl::JourneyPattern',
    'RouteControl::MinimumLength',
    'RouteControl::OmnibusJourneyPattern',
    'RouteControl::OppositeRouteTerminus',
    'RouteControl::OppositeRoute',
    'RouteControl::StopPointsInJourneyPattern',
    'RouteControl::UnactivatedStopPoint',
    'RouteControl::ZDLStopArea',
    'RoutingConstraintZoneControl::MaximumLength',
    'RoutingConstraintZoneControl::MinimumLength',
    'RoutingConstraintZoneControl::UnactivatedStopPoint',
    'VehicleJourneyControl::Delta',
    'VehicleJourneyControl::WaitingTime',
    'VehicleJourneyControl::Speed',
    'VehicleJourneyControl::TimeTable',
    'VehicleJourneyControl::VehicleJourneyAtStops',
    'ComplianceControlSet',
    'ComplianceControlBlock',
    'ComplianceCheck',
    'ComplianceCheckSet',
    'ComplianceCheckBlock',
    'ComplianceCheckResource',
    'ComplianceCheckMessage',
    'Merge',
    'CustomField',
    'SimpleImporter',
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
  config.tenant_names = lambda{  Referential.order("created_from_id asc").pluck(:slug) }
end

##
# Elevator Configuration

# Rails.application.config.middleware.use 'Apartment::Elevators::Generic', lambda { |request|
#   # TODO: supply generic implementation
# }

# Rails.application.config.middleware.use 'Apartment::Elevators::Domain'

# Rails.application.config.middleware.use 'Apartment::Elevators::Subdomain'
