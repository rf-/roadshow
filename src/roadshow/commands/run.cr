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

          Run scenarios from your `scenarios` directory. With no options, run
          the default command for each scenario.
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

        unless File.directory?("scenarios")
          stdout.puts "Error: no directory './scenarios' found".colorize(:red)
          stdout.puts "\nUse 'roadshow generate' to create scenario files."
          raise CommandFailed.new
        end

        config = ProjectConfig.load(YAML.parse(File.read(SCENARIOS_FILENAME)))

        compose_files = Dir["scenarios/*.docker-compose.yml"].map do |path|
          {path, File.basename(path, ".docker-compose.yml")}
        end

        if options.scenario
          compose_files.select! { |(path, name)| name == options.scenario }

          if compose_files.empty?
            stdout.puts "Error: no scenario '#{options.scenario}' found".colorize(:red)
            raise CommandFailed.new
          end
        end

        success = compose_files.reduce(true) do |success, (path, name)|
          if success
            stdout.puts "\nRunning scenario: #{name}\n".colorize.bold

            args = ["-f", path, "run", "--rm", "scenario"]

            if (command = options.command)
              args = args.concat(command)
            end

            Process.run(
              "docker-compose",
              args,
              input: stdin,
              output: stdout,
              error: stdout,
              env: { "COMPOSE_PROJECT_NAME" => config.project }
            ).success?
          else
            stdout.puts "\nSkipping scenario: #{name}\n".colorize.bold

            false
          end
        end

        raise CommandFailed.new unless success
      end
    end
  end
end
