# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

use Chouette::PrometheusExporter

run Rails.application
Rails.application.load_server
