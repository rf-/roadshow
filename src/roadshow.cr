require "colorize"
require "json"
require "option_parser"

require "./roadshow/*"
require "./roadshow/commands/*"

module Roadshow
  class UnknownCommand < Exception
  end

  class InvalidArgument < Exception
  end

  class CommandFailed < Exception
  end

  def self.run
    command = ARGV.shift?

    if command
      STDIN.cooked do
        get_command(command).run(ARGV)
      end
    else
      print_usage
    end
  rescue UnknownCommand
    puts "Unknown command: #{command}".colorize(:red)
    print_usage
    exit 1
  rescue CommandFailed
    exit 2
  end

  def self.print_usage
    puts <<-HELP
    Usage: roadshow <command> [<options>]

    Commands:
       help        Get help about a command
    HELP
  end

  # NOTE: This should be `Command | Nil`, but it's not because of technical
  # limitations of Crystal.
  def self.get_command(name) : Command
    case name
    when "help"
      Commands::Help.new
    else
      raise UnknownCommand.new
    end
  end
end

Roadshow.run
