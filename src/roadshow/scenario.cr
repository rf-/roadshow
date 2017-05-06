module Roadshow
  # A class describing a scenario.
  #
  # TODO: Split into ScenarioFragment (with nullable fields) and Scenario (with
  # non-nullable fields).
  class Scenario
    extend ConfigUtils

    getter project_name, name, from, cmd, service, volumes

    def self.load(project_name : String,
                  name : String?,
                  data : Hash(String, YAML::Type)) : Scenario
      cmd = get_string(data, "cmd")
      from = get_string(data, "from")

      service_hash = get_hash(data, "service")
      service = Service.load(service_hash) if service_hash

      volumes = get_hash(data, "volumes").try(&.keys) || [] of String

      new(
        project_name: project_name,
        name: name,
        from: from,
        cmd: cmd,
        service: service,
        volumes: volumes
      )
    end

    def initialize(@project_name : String,
                   @name : String?,
                   @from : String?,
                   @cmd : String?,
                   @service : Service?,
                   @volumes : Array(String))
    end

    # Merge the other scenario into this one, overwriting or appending to
    # fields as appropriate.
    def merge(other : Scenario)
      service = @service

      Scenario.new(
        project_name: other.project_name || @project_name,
        name: other.name || @name,
        from: other.from || @from,
        cmd: other.cmd || @cmd,
        service: service ? service.merge(other.service) : other.service,
        volumes: @volumes | other.volumes
      )
    end

    # Make sure that all required fields are present. If any are missing, raise
    # an InvalidConfig error. We can't do this at the type level because
    # config can be split between the `shared` and `scenarios` sections.
    def validate!
      {from: @from, cmd: @cmd, service: @service}.each do |key, value|
        if value.nil?
          raise InvalidConfig.new("Scenario '#{@name}' is missing required field '#{key}'")
        end
      end
    end

    # Generate a Dockerfile for this scenario.
    def to_dockerfile : String
      <<-DOCKERFILE
      FROM #{@from.try { |s| gsub_name(s) }}
      RUN mkdir -p /scenario
      WORKDIR /scenario
      ENV LANG=C.UTF-8
      CMD #{@cmd.try { |s| gsub_name(s) }}\n
      DOCKERFILE
    end

    def dockerfile_name : String
      "#{@name}.dockerfile"
    end

    # Generate a docker-compose.yml for this scenario.
    def to_docker_compose_yml : String
      service = @service
      raise "Assertion failure" if service.nil? # Unreachable because of validation

      service_volumes =
        ["..:/scenario"] + service.volumes.map { |v| gsub_name(v) }

      service_environment = service
        .environment
        .map { |key, value| {gsub_name(key), gsub_name(value.to_s)} }
        .to_h

      volumes = @volumes
        .map { |volume_name| {gsub_name(volume_name), {} of String => String} }
        .to_h

      {
        "version"  => "2",
        "services" => {
          "scenario" => {
            "build" => {
              "context"    => "..",
              "dockerfile" => "scenarios/#{dockerfile_name}",
            },
            "image"       => image_name,
            "volumes"     => service_volumes,
            "environment" => service_environment,
          },
        },
        "volumes" => volumes,
      }.to_yaml
    end

    def docker_compose_name : String
      "#{@name}.docker-compose.yml"
    end

    def image_name : String
      "#{@project_name}_scenario_#{@name}"
    end

    def volume_names : Array(String)
      @volumes.map { |v| "#{@project_name}_#{gsub_name(v)}" }
    end

    private def gsub_name(value : String?) : String?
      if value.nil?
        value
      else
        value.gsub(/{{scenario_name}}/, @name.to_s)
      end
    end

    class Service
      extend ConfigUtils

      def self.load(data : Hash(String, YAML::Type)) : Service
        environment = (get_hash(data, "environment") || {} of String => String)
          .map { |k, v| {k, v.to_s} }
          .to_h

        volumes = (get_array(data, "volumes") || [] of YAML::Type).map(&.to_s)

        new(
          environment: environment,
          volumes: volumes
        )
      end

      getter environment, volumes

      def initialize(@environment : Hash(String, String),
                     @volumes : Array(String))
      end

      # Merge the other scenario into this one, overwriting or appending to
      # fields as appropriate.
      def merge(other : Service?)
        if other.nil?
          self
        else
          Service.new(
            environment: @environment.merge(other.environment),
            volumes: @volumes + other.volumes
          )
        end
      end
    end
  end
end
