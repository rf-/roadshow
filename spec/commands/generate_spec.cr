require "../spec_helper"

describe Roadshow::Commands::Generate do
  it "generates basic Docker and Docker Compose configuration" do
    SpecHelper.in_project("simple") do
      begin
        FileUtils.mv("scenarios", "expected_scenarios")

        output = SpecHelper.run!(["generate"])
        output.should eq("Generated files in scenarios/.")

        File.exists?("scenarios").should eq(true)

        Dir["expected_scenarios/*"].each do |path|
          File.read(path.sub(/expected_/, "")).should eq(File.read(path))
        end
      ensure
        FileUtils.rm_rf("scenarios")
        FileUtils.mv("expected_scenarios", "scenarios")
      end
    end
  end

  it "generates Docker and Docker Compose configuration with volumes" do
    SpecHelper.in_project("ruby") do
      begin
        FileUtils.mv("scenarios", "expected_scenarios")
        FileUtils.mkdir("scenarios")

        output = SpecHelper.run!(["generate"])
        output.should eq("Generated files in scenarios/.")

        File.exists?("scenarios").should eq(true)

        Dir["expected_scenarios/*"].each do |path|
          File.read(path.sub(/expected_/, "")).should eq(File.read(path))
        end
      ensure
        FileUtils.rm_rf("scenarios")
        FileUtils.mv("expected_scenarios", "scenarios")
      end
    end
  end

  it "errors if no scenarios.yml exists" do
    SpecHelper.in_project("empty") do
      status, output = SpecHelper.run(["generate"])

      status.should eq(2)
      output.should contain("Error: no file './scenarios.yml' found")
    end
  end

  it "errors if `scenarios` exists as a non-directory" do
    SpecHelper.in_project("simple") do
      begin
        FileUtils.mv("scenarios", "expected_scenarios")

        FileUtils.touch("scenarios")

        status, output = SpecHelper.run(["generate"])

        status.should eq(2)
        output.should contain(
          "Error: Unable to create directory './scenarios': File exists"
        )
      ensure
        FileUtils.rm_rf("scenarios")
        FileUtils.mv("expected_scenarios", "scenarios")
      end
    end
  end
end
