class Logger::Formatter
    def call(severity, time, program_name, message)
      json_log = {
        level: severity,
        time: time,
        msg: message,
        trace_id: '00000000000000000000000000000000',
        span_id: '0000000000000000',
        trace_flags: '00',
        node_id: RAILS_NODE_ID,
        progname: program_name || PROGRAM_NAME,
      }.to_json

      STDOUT.puts(json_log)
    end
end
