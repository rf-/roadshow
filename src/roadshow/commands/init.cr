module Roadshow
  module Commands
    class InitOptions
    end

    class Init < Command(InitOptions)
      def parser(stdout : IO, options = InitOptions.new)
        OptionParser.new do |parser|
          parser.banner = <<-BANNER
          Usage: roadshow init

          Generate a basic `#{SCENARIOS_FILENAME}` file for your project.
          BANNER
        end
      end

      def run(stdin : IO, stdout : IO, options : InitOptions)
        if File.exists?(SCENARIOS_FILENAME)
          stdout.puts "Error: file '#{SCENARIOS_FILENAME}' already exists".colorize(:red)
          raise CommandFailed.new
        end

        project_name = File.basename(Dir.current).gsub(/[\W]+/, "")

        content = <<-YAML
        project: #{project_name}

        # This configuration is shared by all of your scenarios, except where
        # they override it. The format is identical to an individual scenario.
        shared:
          # Specify the value to pass into FROM in the Dockerfile (i.e.,
          # what image to use as a starting point for this scenario).
          from: bash

          # Specify the value to pass into CMD in the Dockerfile. Like CMD, the
          # argument can be a string or an array.
          cmd: "echo 'Hello world!'"

        # The individual scenarios.
        scenarios:
          one:
          two:\n
        YAML

        File.write(SCENARIOS_FILENAME, content)

        stdout.puts "Generated file './#{SCENARIOS_FILENAME}'."
      end
    end
  end
end
