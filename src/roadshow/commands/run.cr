module Roadshow
  module Commands
    class RunOptions
      property :command
      @command : Array(String)? = nil

      property :scenario
      @scenario : String? = nil
    end

    class Run < Command(RunOptions)
      def parser(stdout : IO, options = RunOptions.new)
        OptionParser.new do |parser|
          parser.banner = <<-BANNER
          Usage: roadshow run [command]

          Run scenarios from your `#{OUTPUT_DIRECTORY}` directory. With no
          options, run the default command for each scenario.
          BANNER

          parser.separator

          parser.on("-s", "--scenario=NAME", "The name of the scenario to run") do |scenario|
            options.scenario = scenario
          end

          parser.invalid_option do |_|
            # Ignore "invalid" options since we'll pass them to docker-compose
          end

          parser.unknown_args do |before_dashes, after_dashes|
            options.command = before_dashes + after_dashes
          end
        end
      end

      def run(stdin : IO, stdout : IO, options : RunOptions)
        unless File.exists?(SCENARIOS_FILENAME)
          stdout.puts "Error: no file './#{SCENARIOS_FILENAME}' found".colorize(:red)
          stdout.puts "\nUse 'roadshow init' to generate one."
          raise CommandFailed.new
        end

        unless File.directory?(OUTPUT_DIRECTORY)
          stdout.puts "Error: no directory './#{OUTPUT_DIRECTORY}' found".colorize(:red)
          stdout.puts "\nUse 'roadshow generate' to create scenario files."
          raise CommandFailed.new
        end

        config = ProjectConfig.load(YAML.parse(File.read(SCENARIOS_FILENAME)))
        scenarios = config.scenarios

        if options.scenario
          scenarios.select! { |scenario| scenario.name == options.scenario }

          if scenarios.empty?
            stdout.puts "Error: no scenario '#{options.scenario}' found".colorize(:red)
            raise CommandFailed.new
          end
        end

        success = scenarios.reduce(true) do |success, scenario|
          if success
            stdout.puts "\nRunning scenario: #{scenario.name}\n".colorize.bold

            compose_file = "#{OUTPUT_DIRECTORY}/#{scenario.name}.docker-compose.yml"
            args = ["-f", compose_file, "run", "--rm", "scenario"]

            if (command = options.command)
              args = args.concat(command)
            end

            Process.run(
              "docker-compose",
              args,
              input: stdin,
              output: stdout,
              error: stdout,
              env: {"COMPOSE_PROJECT_NAME" => config.project}
            ).success?
          else
            stdout.puts "\nSkipping scenario: #{scenario.name}\n".colorize.bold
            false
          end
        end

        raise CommandFailed.new unless success
      end
    end
  end
end
