require 'securerandom'
require "opentelemetry/sdk"
require 'rack/request'

require_relative "logger_active_record_json"

# # Export traces to console by default
# # see https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/sdk/lib/opentelemetry/sdk/configurator.rb#L175-L197
# ENV['OTEL_TRACES_EXPORTER'] ||= 'otlp'

# # Configure propagator
# # see https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/sdk/lib/opentelemetry/sdk/configurator.rb#L199-L216
# ENV['OTEL_PROPAGATORS'] ||= 'tracecontext,baggage,b3'


# MiddlewareLogger this code is based on below link with modification.
# https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/examples/http/server.rb
module MiddlewareLogger
  class RequestContextMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      start_time = Time.now

      # Extract context from request headers.
      # This to continue the span if client has sent some propagator key into request header.
      context = OpenTelemetry.propagation.extract(
        env,
        # see https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/common/lib/opentelemetry/common/propagation.rb#L22
        # and https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/common/lib/opentelemetry/common/propagation/rack_env_getter.rb
        getter: OpenTelemetry::Common::Propagation.rack_env_getter,
      )

      # Example: get OpenTelemetry trace id.
      # Trace ID will always the same as traceparent (if exist and continue from client),
      # or from new current span.
      # trace_id = OpenTelemetry::Trace.current_span.context.trace_id.unpack1('H*') # Unpack to hex

      # We use MyAppTracer that we defined in config/initializers/opentelemetry.rb
      # For attribute naming, see
      # https://github.com/open-telemetry/opentelemetry-specification/blob/v1.19.0/specification/trace/semantic_conventions/http.md#http-server
      attributes = {
        'component' => 'http',
        'http.method' => env['REQUEST_METHOD'],
        'http.route' => env['PATH_INFO'],
        'http.url' => env['REQUEST_URI'],
      }

      # Span name SHOULD be set to route:
      span_name = "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
      span = MyAppTracer.start_span(span_name, with_parent: context, attributes: attributes)

      # Extract relevant information from the request object
      # see full object here https://rubydoc.info/gems/rack/Rack/Request
      request = Rack::Request.new(env)

      req_method = request.request_method || ''
      req_path = request.path || ''
      req_url = env['REQUEST_URI'] || ''
      req_user_agent = request.user_agent || ''
      req_remote_ip = request.ip || ''

      # Get X-Request-ID value header. This is non W3 standard headers: https://stackoverflow.com/a/27174552
      # But, Heroku has blog about this https://blog.heroku.com/http_request_id_s_improve_visibility_across_the_application_stack
      request_id = SecureRandom.uuid()

      # Get header request values
      req_headers = {}
      req_headers_filter = env.select { |key, value| key.start_with?('HTTP_') }
      req_headers_filter.each do |key, value|
        if key.downcase == 'X-Request-ID'.downcase
            request_id = value.chomp()
        end
        req_headers[key] = value
      end

      # Pass the information to the logger
      log_data = {
        request: {
          method: req_method,
          path: req_path,
          url: req_url,
          user_agent: req_user_agent,
          remote_ip: req_remote_ip,
          # uncomment if you need all request header passed in every log.
          # But, this will return a big object that makes your log hard to see.
          # header: req_headers,
        },
      }

      # Prepare default response
      resp_status, resp_headers, resp_body = 200, {}, ''

      # Activate the extracted context
      # set the span as the current span in the OpenTelemetry context
      OpenTelemetry::Trace.with_span(span) do
        # Call the next middleware in the chain
        # Run application stack
        span.set_attribute('request_id', request_id)

        resp_status, resp_headers, resp_body = @app.call(env)

        span.set_attribute('http.status_code', resp_status)
      end

      # Inject "traceparent" to header response
      # see https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-sdk/v1.2.0/sdk/lib/opentelemetry/sdk/configurator.rb#L17
      OpenTelemetry.propagation.inject(resp_headers)

      # Inject "X-Request-Id" to header response.
      # The request id must the same as request id if any, if not we already generated one during getting request headers.
      resp_headers['X-Request-Id'] = request_id

      # Calculate process latency
      elapsed_time = (Time.now - start_time) * 1000

      log_data[:response] = {
        status: resp_status,
        header: resp_headers,
        latency: elapsed_time,
      }

      # return the response after it processed on the next call
      return resp_status, resp_headers, resp_body
    rescue Exception => e
      # set the span status to error if an exception is raised
      span.record_exception(e)

      # re-raise the exception
      raise e

    ensure
      MyLogger.info_ctx('access log', log_data)

      # Clear the request context data from the thread-local variable
      Thread.current[:request_id] = nil

      # end the span when the request is complete
      span.finish
    end

   end
end