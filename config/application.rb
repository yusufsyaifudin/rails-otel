require_relative "boot"

require "rails/all"

require_relative "middleware_otel"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsOtel
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.watchable_dirs['lib'] = [:rb]

    # Add a callback to shut down the OpenTelemetry exporter and SDK
    config.after_initialize do
      at_exit do
        OTEL_EXPORTER.shutdown
      end
    end

    # push the MiddlewareLogger::RequestContextMiddleware to head of middleware stack
    config.middleware.insert_before(0, MiddlewareLogger::RequestContextMiddleware)

  end
end
