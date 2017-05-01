module Roadshow
  # A class representing the contents of a `scenarios.yml` file (i.e., the
  # whole state of the project's configuration).
  class ProjectConfig
    extend ConfigUtils

    @finalized_scenarios : Array(Scenario)?

    def self.load(data : YAML::Any)
      case (raw_data = data.raw)
      when Hash
        project = get_string!(raw_data, "project")

        shared = Scenario.load(project, nil, get_hash!(raw_data, "shared"))

        scenarios_hash = get_hash!(raw_data, "scenarios")
        scenarios = scenarios_hash.map do |name, _|
          Scenario.load(project, name, get_hash!(scenarios_hash, name))
        end

        new(project: project, shared: shared, scenarios: scenarios)
      else
        raise InvalidConfig.new("The config file must be a YAML hash")
      end
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
