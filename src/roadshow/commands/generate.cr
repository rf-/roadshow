module Roadshow
  module Commands
    class GenerateOptions
    end

    class Generate < Command(GenerateOptions)
      def parser(stdout : IO, options = GenerateOptions.new)
        OptionParser.new do |parser|
          parser.banner = <<-BANNER
          Usage: roadshow generate

          Based on your project's `#{SCENARIOS_FILENAME}`, generate Docker and
          Docker Compose configuration for each of your scenarios.
          BANNER
        end
      end

      def run(stdin : IO, stdout : IO, options : GenerateOptions)
        begin
          FileUtils.mkdir_p(OUTPUT_DIRECTORY)
        rescue e
          stdout.puts "Error: #{e.message}".colorize(:red)
          raise CommandFailed.new
        end

        unless File.exists?(SCENARIOS_FILENAME)
          stdout.puts "Error: no file './#{SCENARIOS_FILENAME}' found".colorize(:red)
          stdout.puts "\nUse 'roadshow init' to generate one."
          raise CommandFailed.new
        end

        config = ProjectConfig.load(YAML.parse(File.read(SCENARIOS_FILENAME)))

        config.scenarios.each do |scenario|
          File.write(
            "#{OUTPUT_DIRECTORY}/#{scenario.dockerfile_name}",
            scenario.to_dockerfile
          )

          File.write(
            "#{OUTPUT_DIRECTORY}/#{scenario.docker_compose_name}",
            scenario.to_docker_compose_yml
          )
        end

        stdout.puts "Generated files in #{OUTPUT_DIRECTORY}/."
      rescue e : InvalidConfig
        stdout.puts "Error: #{e.message}".colorize(:red)
      end
    end
  end
end
