module Roadshow
  class Command(Options)
    # NOTE: This should be `Command | Nil`, but it's not because of limitations
    # of Crystal.
    def self.get_command(name) : Command
      case name
      when "help"
        Commands::Help.new
      when "init"
        Commands::Init.new
      when "generate"
        Commands::Generate.new
      when "run"
        Commands::Run.new
      when "cleanup"
        Commands::Cleanup.new
      else
        raise UnknownCommand.new
      end
    end

    def run(stdin : IO, stdout : IO, args : Array(String)) : Void
      options = Options.new
      parser = parser(stdout, options)
      parser.parse(args)
      run(stdin, stdout, options)
    rescue e : OptionParser::InvalidOption | OptionParser::MissingOption
      stdout.puts e.message.colorize(:red)
      stdout.puts parser(stdout)
      raise CommandFailed.new
    rescue InvalidArgument
      stdout.puts parser(stdout)
      raise CommandFailed.new
    end

    def help : String
      parser(nil).to_s
    end

    def parser(stdout : IO, options : Options = Options.new) : OptionParser
      raise "Not implemented"
    end

    def run(stdin : IO, stdout : IO, options : Options) : Void
      raise "Not implemented"
    end
  end
end
