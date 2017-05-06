module Roadshow
  module Commands
    class HelpOptions
      property :command
      @command : String | Nil = nil
    end

    class Help < Command(HelpOptions)
      def parser(stdout : IO, options = HelpOptions.new)
        OptionParser.new do |parser|
          parser.banner = <<-BANNER
          Usage: roadshow help [COMMAND]

          Get help about a specific subcommand.
          BANNER

          parser.unknown_args do |args|
            non_options = args.reject { |a| a.starts_with?("-") }
            options.command = non_options.shift?

            if non_options.size > 0
              stdout.puts
              stdout.puts "Error: Unexpected arguments: #{non_options.join(", ")}".colorize(:red)
              raise InvalidArgument.new
            end
          end
        end
      end

      def run(stdin : IO, stdout : IO, options : HelpOptions)
        if options.command
          begin
            command = Roadshow::Command.get_command(options.command)
            stdout.puts command.parser(stdout)
          rescue UnknownCommand
            stdout.puts "Error: Command not found: #{options.command}".colorize(:red)
            stdout.puts
            raise CommandFailed.new
          end
        else
          stdout.puts parser(stdout)
        end
      end
    end
  end
end
