# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

require 'prometheus/middleware/exporter'
use Chouette::PrometheusExporter

run ChouetteIhm::Application
