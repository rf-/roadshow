require "spec"
require "../src/roadshow/*"

module SpecHelper
  def self.in_project(name : String = "empty_project", &block)
    dir = "spec/projects/#{name}"
    existing_files = Dir["#{dir}/**"].to_set

    begin
      FileUtils.cd(dir, &block)
    ensure
      Dir["#{dir}/**"].each do |path|
        FileUtils.rm_rf(path) unless existing_files.includes?(path)
      end
    end
  end

  def self.run(args : Array(String)) : {Int32, String}
    input = IO::Memory.new
    output = IO::Memory.new

    status = Roadshow::CLI.run(input, output, args)

    {status, output.to_s.chomp}
  end

  def self.run!(args : Array(String)) : String
    status, output = run(args)

    if status == 0
      output
    else
      raise "Running with args #{args.inspect} failed:\n#{output}"
    end
  end
end
