require "../spec_helper"

describe Roadshow::Commands::Init do
  it "creates a scenarios.yml file if one doesn't exist" do
    SpecHelper.in_project("empty") do
      output = SpecHelper.run!(["init"])

      output.should eq("Generated file './scenarios.yml'.")
      File.exists?("scenarios.yml").should eq(true)

      contents = YAML.parse(File.read("scenarios.yml"))
      contents["project"].should eq("empty")
    end
  end

  it "errors out if the file already exists" do
    SpecHelper.in_project("empty") do
      FileUtils.touch("scenarios.yml")

      status, output = SpecHelper.run(["init"])

      status.should eq(2)
      output.should contain("Error: file 'scenarios.yml' already exists")
      File.exists?("scenarios.yml").should eq(true)
    end
  end
end
