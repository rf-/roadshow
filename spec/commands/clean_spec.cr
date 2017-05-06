require "../spec_helper"

describe Roadshow::Commands::Clean do
  it "cleans up images" do
    SpecHelper.in_project("simple") do
      # First, run the scenarios to create images.
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
end
