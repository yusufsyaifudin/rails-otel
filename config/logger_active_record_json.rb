require 'securerandom'

# Class ActiveSupport::Logger will duck-type the original ActiveSupport::Logger class
class ActiveSupport::Logger

  def initialize(*args)
    super(*args)
  end

  # format_message will override the method format_message on Ruby class Logger here:
  # https://github.com/ruby/logger/blob/4e8d9e27fd3b8f916cd3b370b97359f67e02c4bb/lib/logger.rb#L742-L744
  # 4e8d9e2 is the commit release of version https://github.com/ruby/logger/releases/tag/v1.5.3
  #
  # This because ActiveSupport::Logger duck-typing (extends) class Logger as seen here
  # https://github.com/rails/rails/blob/7c70791470fc517deb7c640bead9f1b47efb5539/activesupport/lib/active_support/logger.rb#L8
  # 7c70791 is commit id on release tag https://github.com/rails/rails/releases/tag/v7.0.4.2
  #
  # format_message should return void, so we do return with no arguments
  # We print it as JSON.
  def format_message(severity, timestamp, progname, msg)
    # prepare log and print it
    log = format_json(severity, timestamp, progname, msg, nil)
    STDOUT.puts(log)
    return
  end

  # format_json will format *args as JSON structured format.
  # This function will return JSON, and not print it.
  # The format MUST the same as format_message except this has "attributes" key.
  # In Ruby, you can use the splat operator * to define a variadic argument,
  # which allows a method to accept an arbitrary number of arguments. To add type checking to a variadic argument,
  # you can use the syntax argname : Type*.
  def format_json(severity, time, progname, msg, data, *args)
    current_span = OpenTelemetry::Trace.current_span
    trace_id = current_span.context.trace_id
    hex_trace_id = trace_id.unpack1('H*')

    span_id = current_span.context.span_id
    hex_span_id = span_id.unpack1('H*')

    attributes = []
    args.each_with_index do |arg, index|
      # The next argument can be anything.
      attributes.push(arg)
    end

    # prepare log and return it
    log = {
      level: severity,
      time: time,
      msg: msg,
      trace_id: hex_trace_id,
      span_id: hex_span_id,
      trace_flags: '00',
      node_id: RAILS_NODE_ID,
      progname: progname || PROGRAM_NAME,
    }

    # Get request id from Thread context.
    # It must not be empty since we should always set it in the first middleware.
    if !Thread.current[:request_id].nil? && !Thread.current[:request_id].empty?
      log[:request_id] = Thread.current[:request_id]
    end

    # Check if a variable is a Hash using instance_of?
    # If data is not a Hash, it will become attributes.
    if !data.nil? && !data.empty?
      if data.instance_of?(Hash)
        log[:data] = data
      else
        attributes.push(data)
      end
    end

    if !attributes.nil? && !attributes.empty?
      log[:attributes] = attributes
    end

    return log.to_json
  end

  # debug_ctx will format the arguments as JSON and the print it using STDOUT.puts
  # This uses block (debug{}) instead of function call (debug()) to make it memory efficient.
  # https://stackoverflow.com/a/30144402
  # Since the original Ruby ::Logger has debug, info, warn, error, fatal and unknown logger,
  # we add suffixes _ctx which take multiple arguments and the first argument must String which is the message log.
  # We get the program name using self as it access the parent class:
  # https://github.com/ruby/logger/blob/4e8d9e27fd3b8f916cd3b370b97359f67e02c4bb/lib/logger.rb#L420-L421
  def debug_ctx(msg, data, *args)
    self.debug do
      log = format_json("DEBUG", Time.now, self.progname, msg, data, *args)
      STDOUT.puts(log)
      return ""
    end
  end

  def info_ctx(msg, data, *args)
    self.info do
      log = format_json("INFO", Time.now, self.progname, msg, data, *args)
      STDOUT.puts(log)
      return ""
    end
  end

  def warn_ctx(msg, data)
    self.warn do
      log = format_json("WARN", Time.now, self.progname, msg, data, *args)
      STDOUT.puts(log)
      return ""
    end
  end

  def error_ctx(msg, data)
    self.error do
      log = format_json("ERROR", Time.now, self.progname, msg, data, *args)
      STDOUT.puts(log)
      return ""
    end
  end

  def fatal_ctx(msg, data)
    self.fatal do
      log = format_json("FATAL", Time.now, self.progname, msg, data, *args)
      STDOUT.puts(log)
      return ""
    end
  end

  def unknown_ctx(msg, data, *args)
    self.debug do
      log = format_json("UNKNOWN", Time.now, self.progname, msg, data)
      STDOUT.puts(log)
      return ""
    end
  end

end # end of class Json

MyLogger = ActiveSupport::Logger.new(STDOUT)