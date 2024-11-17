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

  it "cleans up containers" do
    SpecHelper.in_project("databases") do
      begin
        SpecHelper.run!(["run"])

        images = `docker images`
        images.should contain("databases_scenario_mysql")
        images.should contain("databases_scenario_postgres")

        volumes = `docker volume ls`
        volumes.should contain("databases_bundle_mysql")
        volumes.should contain("databases_data_mysql")
        volumes.should contain("databases_bundle_postgres")
        volumes.should contain("databases_data_postgres")

        containers = `docker ps`
        containers.should contain("databases-mysql-1")
        containers.should contain("databases-postgres-1")

        output = SpecHelper.run!(["clean"])
        output.should contain("databases-mysql-1")
        output.should contain("databases-postgres-1")
        output.should contain("Untagged: databases_scenario_mysql:latest")
        output.should contain("Untagged: databases_scenario_postgres:latest")
        output.should contain("databases_bundle_mysql")
        output.should contain("databases_data_mysql")
        output.should contain("databases_bundle_postgres")
        output.should contain("databases_data_postgres")

        images = `docker images`
        images.should_not contain("databases_scenario_mysql")
        images.should_not contain("databases_scenario_postgres")

        volumes = `docker volume ls`
        volumes.should_not contain("databases_bundle_mysql")
        volumes.should_not contain("databases_data_mysql")
        volumes.should_not contain("databases_bundle_postgres")
        volumes.should_not contain("databases_data_postgres")

        containers = `docker ps`
        containers.should_not contain("databases-mysql-1")
        containers.should_not contain("databases-postgres-1")
      ensure
        FileUtils.rm("scenarios/mysql.gemfile.lock")
        FileUtils.rm("scenarios/postgres.gemfile.lock")
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

  it "cleans up only containers" do
    SpecHelper.in_project("databases") do
      begin
        SpecHelper.run!(["run"])

        images = `docker images`
        images.should contain("databases_scenario_mysql")
        images.should contain("databases_scenario_postgres")

        volumes = `docker volume ls`
        volumes.should contain("databases_bundle_mysql")
        volumes.should contain("databases_data_mysql")
        volumes.should contain("databases_bundle_postgres")
        volumes.should contain("databases_data_postgres")

        containers = `docker ps`
        containers.should contain("databases-mysql-1")
        containers.should contain("databases-postgres-1")

        output = SpecHelper.run!(["clean", "-c"])
        output.should contain("databases-mysql-1")
        output.should contain("databases-postgres-1")
        output.should_not contain("Untagged: databases_scenario_mysql:latest")
        output.should_not contain("Untagged: databases_scenario_postgres:latest")
        output.should_not contain("databases_bundle_mysql")
        output.should_not contain("databases_data_mysql")
        output.should_not contain("databases_bundle_postgres")
        output.should_not contain("databases_data_postgres")

        images = `docker images`
        images.should contain("databases_scenario_mysql")
        images.should contain("databases_scenario_postgres")

        volumes = `docker volume ls`
        volumes.should contain("databases_bundle_mysql")
        volumes.should contain("databases_data_mysql")
        volumes.should contain("databases_bundle_postgres")
        volumes.should contain("databases_data_postgres")

        containers = `docker ps`
        containers.should_not contain("databases-mysql-1")
        containers.should_not contain("databases-postgres-1")
      ensure
        FileUtils.rm("scenarios/mysql.gemfile.lock")
        FileUtils.rm("scenarios/postgres.gemfile.lock")
      end
    end
  end
end
