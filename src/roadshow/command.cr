module Roadshow
  class Command(Options)
    def run(args : Array(String)) : Void
      options = Options.new
      parser = parser(options)
      parser.parse(args)
      run(options)
    rescue e : OptionParser::InvalidOption | OptionParser::MissingOption
      puts e.message.colorize(:red)
      puts parser
      raise CommandFailed.new
    rescue InvalidArgument
      puts parser
      raise CommandFailed.new
    end

    def help : String
      parser(nil).to_s
    end

    def parser(options : Options = Options.new) : OptionParser
      raise "Not implemented"
    end

    def run(options : Options) : Void
      raise "Not implemented"
    end
  end
end
