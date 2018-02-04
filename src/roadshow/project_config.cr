module Roadshow
  # A class representing the contents of a `scenarios.yml` file (i.e., the
  # whole state of the project's configuration).
  class ProjectConfig
    getter project

    @finalized_scenarios : Array(Scenario)?

    def self.load(data : YAML::Any)
      project = data["project"].as_s

      shared = Scenario.load(project, nil, data["shared"].as_h)

      scenarios_hash = data["scenarios"].as_h
      scenarios = scenarios_hash.map do |name, _|
        Scenario.load(project, name.to_s, YAML::Any.new(scenarios_hash[name]).as_h)
      end

      new(project: project, shared: shared, scenarios: scenarios)
    end

    def initialize(@project : String,
                   @shared : Scenario?,
                   @scenarios : Array(Scenario))
    end

    # Return an array of configured scenarios, fully populated and validated.
    def scenarios : Array(Scenario)
      @finalized_scenarios ||= begin
        shared = @shared

        merged_scenarios =
          if shared.nil?
            @scenarios
          else
            @scenarios.map do |scenario|
              shared.merge(scenario)
            end
          end

        merged_scenarios.each do |scenario|
          scenario.validate!
        end

        merged_scenarios
      end
    end
  end
end
