module Roadshow
  module Commands
    class CleanOptions
      property :containers
      @containers : Bool = true

      property :images
      @images : Bool = true

      property :volumes
      @volumes : Bool = true
    end

    class Clean < Command(CleanOptions)
      def parser(stdout : IO, options = CleanOptions.new)
        OptionParser.new do |parser|
          parser.banner = <<-BANNER
          Usage: roadshow clean [options]

          Based on your project's `#{SCENARIOS_FILENAME}`, remove all Docker
          images created to run your project's scenarios.
          BANNER

          parser.separator

          parser.on("-c", "--containers-only", "Only remove containers") do
            options.images = false
            options.volumes = false
          end

          parser.on("-i", "--images-only", "Only remove images") do
            options.containers = false
            options.volumes = false
          end

          parser.on("-v", "--volumes-only", "Only remove volumes") do
            options.containers = false
            options.images = false
          end
        end
      end

      def run(stdin : IO, stdout : IO, options : CleanOptions)
        unless File.exists?(SCENARIOS_FILENAME)
          stdout.puts "Error: no file './#{SCENARIOS_FILENAME}' found".colorize(:red)
          stdout.puts "\nUse 'roadshow init' to generate one."
          raise CommandFailed.new
        end

        config = ProjectConfig.load(YAML.parse(File.read(SCENARIOS_FILENAME)))

        if options.containers
          containers_io = IO::Memory.new

          Roadshow::Process.run(
            "docker",
            ["ps", "-a"],
            input: stdin,
            output: containers_io,
            error: stdout
          ).success? || raise CommandFailed.new

          containers = containers_io.to_s.lines.skip(1).map { |l| l.split[-1].chomp }
          containers_to_delete = containers & config.scenarios.flat_map(&.container_names)

          if containers_to_delete.any?
            Roadshow::Process.run(
              "docker",
              ["rm", "-f"] + containers_to_delete,
              input: stdin,
              output: stdout,
              error: stdout
            ).success? || raise CommandFailed.new
          end
        end

        if options.images
          images_io = IO::Memory.new

          Roadshow::Process.run(
            "docker",
            ["images"],
            input: stdin,
            output: images_io,
            error: stdout
          ).success? || raise CommandFailed.new

          images = images_io.to_s.lines.skip(1).map { |l| l.split[0] }
          images_to_delete = images & config.scenarios.flat_map(&.image_names)

          if images_to_delete.any?
            Roadshow::Process.run(
              "docker",
              ["rmi"] + images_to_delete,
              input: stdin,
              output: stdout,
              error: stdout
            ).success? || raise CommandFailed.new
          end
        end

        if options.volumes
          volumes_io = IO::Memory.new

          Roadshow::Process.run(
            "docker",
            ["volume", "ls"],
            input: stdin,
            output: volumes_io,
            error: stdout
          ).success? || raise CommandFailed.new

          volumes = volumes_io.to_s.lines.skip(1).map { |l| l.split[1] }
          volumes_to_delete = volumes & config.scenarios.flat_map(&.volume_names)

          if volumes_to_delete.any?
            Roadshow::Process.run(
              "docker",
              ["volume", "rm"] + volumes_to_delete,
              input: stdin,
              output: stdout,
              error: stdout
            ).success? || raise CommandFailed.new
          end
        end
      rescue e : InvalidConfig
        stdout.puts "Error: #{e.message}".colorize(:red)
      end
    end
  end
end
