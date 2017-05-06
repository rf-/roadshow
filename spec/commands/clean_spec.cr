require "../spec_helper"

describe Roadshow::Commands::Clean do
  it "cleans up images" do
    SpecHelper.in_project("simple") do
      SpecHelper.run!(["run"])

      images = `docker images`
      images.should contain("simple_scenario_one")
      images.should contain("simple_scenario_two")

      output = SpecHelper.run!(["clean"])
      output.should contain("Untagged: simple_scenario_one:latest")
      output.should contain("Untagged: simple_scenario_two:latest")

      images = `docker images`
      images.should_not contain("simple_scenario_one")
      images.should_not contain("simple_scenario_two")
    end
  end

  it "cleans up volumes" do
    SpecHelper.in_project("ruby") do
      begin
        SpecHelper.run!(["run"])

        images = `docker images`
        images.should contain("ruby_scenario_one")
        images.should contain("ruby_scenario_two")

        volumes = `docker volume ls`
        volumes.should contain("ruby_bundle_one")
        volumes.should contain("ruby_bundle_two")

        output = SpecHelper.run!(["clean"])
        output.should contain("Untagged: ruby_scenario_one:latest")
        output.should contain("Untagged: ruby_scenario_two:latest")
        output.should contain("ruby_bundle_one")
        output.should contain("ruby_bundle_two")

        images = `docker images`
        images.should_not contain("ruby_scenario_one")
        images.should_not contain("ruby_scenario_two")

        volumes = `docker volume ls`
        volumes.should_not contain("ruby_bundle_one")
        volumes.should_not contain("ruby_bundle_two")
      ensure
        FileUtils.rm("scenarios/one.gemfile.lock")
        FileUtils.rm("scenarios/two.gemfile.lock")
      end
    end
  end

  it "cleans up only images" do
    SpecHelper.in_project("ruby") do
      begin
        SpecHelper.run!(["run"])

        images = `docker images`
        images.should contain("ruby_scenario_one")
        images.should contain("ruby_scenario_two")

        volumes = `docker volume ls`
        volumes.should contain("ruby_bundle_one")
        volumes.should contain("ruby_bundle_two")

        output = SpecHelper.run!(["clean", "-i"])
        output.should contain("Untagged: ruby_scenario_one:latest")
        output.should contain("Untagged: ruby_scenario_two:latest")
        output.should_not contain("ruby_bundle_one")
        output.should_not contain("ruby_bundle_two")

        images = `docker images`
        images.should_not contain("ruby_scenario_one")
        images.should_not contain("ruby_scenario_two")

        volumes = `docker volume ls`
        volumes.should contain("ruby_bundle_one")
        volumes.should contain("ruby_bundle_two")
      ensure
        FileUtils.rm("scenarios/one.gemfile.lock")
        FileUtils.rm("scenarios/two.gemfile.lock")
      end
    end
  end

  it "cleans up only volumes" do
    SpecHelper.in_project("ruby") do
      begin
        SpecHelper.run!(["run"])

        images = `docker images`
        images.should contain("ruby_scenario_one")
        images.should contain("ruby_scenario_two")

        volumes = `docker volume ls`
        volumes.should contain("ruby_bundle_one")
        volumes.should contain("ruby_bundle_two")

        output = SpecHelper.run!(["clean", "-v"])
        output.should_not contain("Untagged: ruby_scenario_one:latest")
        output.should_not contain("Untagged: ruby_scenario_two:latest")
        output.should contain("ruby_bundle_one")
        output.should contain("ruby_bundle_two")

        images = `docker images`
        images.should contain("ruby_scenario_one")
        images.should contain("ruby_scenario_two")

        volumes = `docker volume ls`
        volumes.should_not contain("ruby_bundle_one")
        volumes.should_not contain("ruby_bundle_two")
      ensure
        FileUtils.rm("scenarios/one.gemfile.lock")
        FileUtils.rm("scenarios/two.gemfile.lock")
      end
    end
  end
end
