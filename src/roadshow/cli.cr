require "colorize"
require "file_utils"
require "option_parser"
require "yaml"

require "./*"
require "./commands/*"

module Roadshow
  module CLI
    def self.run(stdin, stdout, args) : Int
      command = args.shift?

      if command
        Command.get_command(command).run(stdin, stdout, args)
      else
        print_usage(stdout)
      end

      0
    rescue UnknownCommand
      stdout.puts "Error: Unknown command: #{command}".colorize(:red)
      print_usage(stdout)
      1
    rescue CommandFailed
      2
    end

    def self.print_usage(stdout)
      stdout.puts <<-HELP
      Usage: roadshow <command> [<options>]

      Commands:
         help        Get help about a command
         init        Generate a `#{SCENARIOS_FILENAME}` file
         generate    Generate Docker configuration
         run         Run scenarios with Docker
         clean       Clean up Docker images and volumes
      HELP
    end
  end
end
