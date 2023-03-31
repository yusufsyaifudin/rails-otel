require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

# Custom exporter to make print to STDOUT
class MyExporter < OpenTelemetry::Exporter::OTLP::Exporter
  # Override function here:
  # https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/exporter/otlp/lib/opentelemetry/exporter/otlp/exporter.rb#L79-L90
  def export(span_data, timeout: nil)
    # Custom logic for exporting data goes here
    STDOUT.puts("Exporting data: #{span_data.inspect}")
    return OpenTelemetry::SDK::Trace::Export::SUCCESS
  end
end

# Exporter and Processor configuration
# See list of arguments here https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/exporter/otlp/lib/opentelemetry/exporter/otlp/exporter.rb#L48-L54
# As of March 15th, 2023, the gRPC exporter is not published to Rubygems and marked as not production ready.
# See https://github.com/open-telemetry/opentelemetry-ruby/issues/1337
# So, we can only use HTTP for now.
OTEL_EXPORTER = OpenTelemetry::Exporter::OTLP::Exporter.new(
  endpoint: ENV['OTEL_EXPORTER_OTLP_ENDPOINT'],
)

# Use this custom exporter if we want to log into STDOUT only, or implement another exporter (such as no-operation).
# OTEL_EXPORTER = MyExporter.new()

# See https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/sdk/lib/opentelemetry/sdk/trace/export/batch_span_processor.rb#L47-L53
processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(OTEL_EXPORTER)

OpenTelemetry::SDK.configure do |c|

  c.resource = OpenTelemetry::SDK::Resources::Resource.create({
    OpenTelemetry::SemanticConventions::Resource::SERVICE_NAMESPACE => 'rails-app',
    OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => PROGRAM_NAME.to_s, # Global variable PROGRAM_NAME already defined in config/boot.rb
    OpenTelemetry::SemanticConventions::Resource::SERVICE_INSTANCE_ID => Socket.gethostname(),
    OpenTelemetry::SemanticConventions::Resource::SERVICE_VERSION => "0.0.0", # we can get it from environment variable
  })

  # enables all instrumentation!
  c.use_all()

  # Or, if you prefer to filter specific instrumentation,
  # you can pick some of them like this https://scoutapm.com/blog/configuring-opentelemetry-in-ruby
  ##### Instruments
  # c.use 'OpenTelemetry::Instrumentation::Rack'
  # c.use 'OpenTelemetry::Instrumentation::ActionPack'
  # c.use 'OpenTelemetry::Instrumentation::ActionView'
  # c.use 'OpenTelemetry::Instrumentation::ActiveJob'
  # c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
  # c.use 'OpenTelemetry::Instrumentation::ConcurrentRuby'
  # c.use 'OpenTelemetry::Instrumentation::Faraday'
  # c.use 'OpenTelemetry::Instrumentation::HttpClient'
  # c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
  # c.use 'OpenTelemetry::Instrumentation::PG', {
  #   # By default, this instrumentation includes the executed SQL as the `db.statement`
  #   # semantic attribute. Optionally, you may disable the inclusion of this attribute entirely by
  #   # setting this option to :omit or sanitize the attribute by setting to :obfuscate
  #   db_statement: :obfuscate,
  # }
  # c.use 'OpenTelemetry::Instrumentation::Rails'
  # c.use 'OpenTelemetry::Instrumentation::Redis'
  # c.use 'OpenTelemetry::Instrumentation::RestClient'
  # c.use 'OpenTelemetry::Instrumentation::RubyKafka'
  # c.use 'OpenTelemetry::Instrumentation::Sidekiq'

  # Set OpenTelemetry library logger
  c.logger = Logger.new(STDOUT)

  # Exporter and Processor configuration
  c.add_span_processor(processor)
end

# 'MyAppTracer' can be used throughout your code now
MyAppTracer = OpenTelemetry.tracer_provider.tracer(PROGRAM_NAME, '0.0.0')
