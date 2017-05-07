require "../spec_helper"

describe Roadshow::Commands::Run do
  it "errors if no scenarios directory exists" do
    SpecHelper.in_project("empty") do
      SpecHelper.run!(["init"]) # create scenarios.yml

      status, output = SpecHelper.run(["run"])

      status.should eq(2)
      output.should contain("Error: no directory './scenarios' found")
    end
  end

  it "runs all scenarios for a simple project" do
    SpecHelper.in_project("simple") do
      output = SpecHelper.run!(["run"])
      output.should contain("default command\nscenario one")
      output.should contain("overridden command\nscenario two")
    end
  end

  it "runs one scenario for a simple project" do
    SpecHelper.in_project("simple") do
      output = SpecHelper.run!(["run", "-s", "one"])
      output.should contain("default command\nscenario one")
      output.should_not contain("overridden command\nscenario two")
    end
  end

  it "runs a specific simple command" do
    SpecHelper.in_project("simple") do
      output = SpecHelper.run!(["run", "echo", "'hi'"])
      output.should contain("hi")
    end
  end

  it "cleans up containers automatically" do
    SpecHelper.in_project("simple") do
      SpecHelper.run!(["run"])

      containers = `docker ps -a`
      containers.should_not contain("simple_scenario_one")
      containers.should_not contain("simple_scenario_two")
    end
  end

  it "runs all scenarios for a more complex project" do
    SpecHelper.in_project("ruby") do
      begin
        output = SpecHelper.run!(["run"])
        output.should contain("Failed to load Cuba!\nLoaded Sinatra!")
        output.should contain("Loaded Cuba!\nFailed to load Sinatra!")
      ensure
        FileUtils.rm("scenarios/one.gemfile.lock")
        FileUtils.rm("scenarios/two.gemfile.lock")
      end
    end
  end

  it "runs one scenario for a more complex project" do
    SpecHelper.in_project("ruby") do
      begin
        output = SpecHelper.run!(["run", "-s", "one"])
        output.should contain("Failed to load Cuba!\nLoaded Sinatra!")
        output.should_not contain("Loaded Cuba!\nFailed to load Sinatra!")
      ensure
        FileUtils.rm("scenarios/one.gemfile.lock")
      end
    end
  end

  it "skips subsequent scenarios if one fails" do
    SpecHelper.in_project("ruby") do
      begin
        status, output = SpecHelper.run([
          "run", "bundle", "exec", "ruby", "-e", "require 'cuba'",
        ])
        output.should contain("Running scenario: one")
        output.should contain("cannot load such file -- cuba")
        output.should contain("Skipping scenario: two")
        status.should eq(2)
      ensure
        FileUtils.rm("scenarios/one.gemfile.lock")
      end
    end
  end

  it "runs all scenarios for a project with multiple services" do
    SpecHelper.in_project("databases") do
      begin
        output = SpecHelper.run!(["run"])
        output.should contain("Successfully used mysql2 database!")
        output.should contain("Successfully used postgresql database!")
      ensure
        FileUtils.rm("scenarios/mysql.gemfile.lock")
        FileUtils.rm("scenarios/postgres.gemfile.lock")
        SpecHelper.run!(["clean"]) # Remove containers
      end
    end
  end
end
