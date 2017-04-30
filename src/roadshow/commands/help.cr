module Roadshow
  module Commands
    class HelpOptions
      property :command
      @command : String | Nil = nil
    end

    class Help < Command(HelpOptions)
      def parser(options = HelpOptions.new)
        OptionParser.new do |parser|
          parser.banner = <<-BANNER
          Usage: roadshow help [COMMAND]

          Get help about a specific subcommand.
          BANNER

          parser.separator

          parser.unknown_args do |args|
            non_options = args.reject { |a| a.starts_with?("-") }
            options.command = non_options.shift?

            if non_options.size > 0
              puts "Unexpected arguments: #{non_options.join(", ")}".colorize(:red)
              raise InvalidArgument.new
            end
          end
        end
      end

      def run(options : HelpOptions)
        if options.command
          begin
            command = Roadshow.get_command(options.command)
            puts command.parser
          rescue UnknownCommand
            puts "Command not found: #{options.command}".colorize(:red)
            puts
            raise CommandFailed.new
          end
        else
          puts parser
        end
      end
    end
  end
end
