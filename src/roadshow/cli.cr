require "colorize"
require "json"
require "option_parser"

require "./*"
require "./commands/*"

module Roadshow
  module CLI
    def self.run(stdin, stdout, args) : Int
      command = args.shift?

      if command
        # Use real STDIN here since other IOs won't implement `cooked` (and
        # it's harmless).
        STDIN.cooked do
          Command.get_command(command).run(stdin, stdout, args)
        end
      else
        print_usage(stdout)
      end

      0
    rescue UnknownCommand
      stdout.puts "Unknown command: #{command}".colorize(:red)
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
      HELP
    end
  end
end
