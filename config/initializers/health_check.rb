HealthCheck.setup do |config|
  config.uri = 'healthz'

  config.standard_checks -= [ 'database', 'migrations', 'emailconf' ]
end
