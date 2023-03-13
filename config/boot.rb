ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

require 'securerandom'
require "rails/command" # Allow for base class autoload
require "rails/commands/server/server_command" # Load the ServerCommand class

RAILS_NODE_ID = SecureRandom.uuid
PROGRAM_NAME = ENV['PROGRAM_NAME'] || 'no-service-name'

# https://stackoverflow.com/a/75651939
Rails::Command::ServerCommand.class_eval do
  # print_boot_information override the original method to make all log turn into JSON
  # https://github.com/rails/rails/blob/7c70791470fc517deb7c640bead9f1b47efb5539/railties/lib/rails/commands/server/server_command.rb#L278-L284
  # 7c70791 is commit hash for release tag: https://github.com/rails/rails/releases/tag/v7.0.4.2
  # If you have different version of Rails, this method may not work!
  def print_boot_information(server, url)
    logs = [
      "Booting #{ActiveSupport::Inflector.demodulize(server)}",
      "Rails #{Rails.version} application starting in #{Rails.env} #{url}",
      "Run `bin/rails server --help` for more startup options"
    ]

    ts = Time.now
    logs.each do |log|
      json_log = {
        level: "UNKNOWN",
        time: ts,
        msg: log,
        trace_id: '00000000000000000000000000000000',
        span_id: '0000000000000000',
        trace_flags: '00',
        node_id: RAILS_NODE_ID,
        progname: PROGRAM_NAME,
      }.to_json

      STDOUT.puts(json_log)
    end
  end
end
