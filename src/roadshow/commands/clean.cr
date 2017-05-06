module Roadshow
  module Commands
    class CleanOptions
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

          parser.on("-i", "--images-only", "Only remove images") do
            options.volumes = false
          end

          parser.on("-v", "--volumes-only", "Only remove volumes") do
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

        if options.images
          images_io = IO::Memory.new

          Process.run(
            "docker",
            ["images"],
            input: stdin,
            output: images_io,
            error: stdout
          ).success? || raise CommandFailed.new

          images = images_io.to_s.lines.skip(1).map { |l| l.split[0] }
          images_to_delete = images & config.scenarios.map(&.image_name)

          if images_to_delete.any?
            Process.run(
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

          Process.run(
            "docker",
            ["volume", "ls"],
            input: stdin,
            output: volumes_io,
            error: stdout
          ).success? || raise CommandFailed.new

          volumes = volumes_io.to_s.lines.skip(1).map { |l| l.split[1] }
          volumes_to_delete = volumes & config.scenarios.flat_map(&.volume_names)

          if volumes_to_delete.any?
            Process.run(
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
