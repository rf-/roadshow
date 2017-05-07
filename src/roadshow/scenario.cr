module Roadshow
  # A class describing a scenario.
  #
  # TODO: Split into ScenarioFragment (with nullable fields) and Scenario (with
  # non-nullable fields).
  class Scenario
    extend ConfigUtils

    getter project_name, name, from, cmd, service, other_services, volumes

    def self.load(project_name : String,
                  name : String?,
                  data : Hash(String, YAML::Type)) : Scenario
      cmd = get_string(data, "cmd")
      from = get_string(data, "from")

      service_hash = get_hash(data, "service") || {} of String => YAML::Type
      image_name = name && "#{project_name}_scenario_#{name}"
      service = Service.load(image_name, service_hash)

      other_services_hash = get_hash(data, "services")
      other_services =
        if other_services_hash
          other_services_hash.map do |name, _|
            other_service_hash = get_hash(other_services_hash, name)

            if other_service_hash
              image_name = get_string(other_service_hash, "image")
              {name, Service.load(image_name, other_service_hash)}
            end
          end.compact.to_h
        else
          {} of String => Service
        end

      volumes = get_hash(data, "volumes").try(&.keys) || [] of String

      new(
        project_name: project_name,
        name: name,
        from: from,
        cmd: cmd,
        service: service,
        other_services: other_services,
        volumes: volumes
      )
    end

    def initialize(@project_name : String,
                   @name : String?,
                   @from : String?,
                   @cmd : String?,
                   @service : Service?,
                   @other_services : Hash(String, Service),
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
        other_services: @other_services.merge(other.other_services) do |_, s1, s2|
          s1.merge(s2)
        end,
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

      service_volumes = ["..:/scenario"] + gsub_name(service.volumes)

      volumes = @volumes
        .map { |volume_name| {gsub_name(volume_name), {} of String => String} }
        .to_h

      {
        "version"  => "2",
        "services" => {
          "scenario" => {
            "build" => {
              "context"    => "..",
              "dockerfile" => "#{OUTPUT_DIRECTORY}/#{dockerfile_name}",
            },
            "image"       => service.image_name,
            "volumes"     => service_volumes,
            "environment" => gsub_name(service.environment),
            "links"       => gsub_name(service.links),
          },
        }.merge(
          @other_services.map do |name, service|
            {name, {
              "image"       => service.image_name,
              "volumes"     => gsub_name(service.volumes),
              "environment" => gsub_name(service.environment),
              "links"       => gsub_name(service.links),
            }}
          end.to_h
        ),
        "volumes" => volumes,
      }.to_yaml
    end

    def docker_compose_name : String
      "#{@name}.docker-compose.yml"
    end

    def image_names : Array(String)
      ([@service] + @other_services.values)
        .map { |service| service && service.image_name }
        .compact
    end

    def container_names : Array(String)
      @other_services.keys.map { |name| "#{@project_name}_#{name}_1" }
    end

    def volume_names : Array(String)
      @volumes.map { |v| "#{@project_name}_#{gsub_name(v)}" }
    end

    private def gsub_name(value : Hash(String, V)) : Hash(String, String) forall V
      value
        .map { |key, value| {gsub_name(key), gsub_name(value.to_s)} }
        .to_h
    end

    private def gsub_name(value : Array(String)) : Array(String)
      value.map { |s| gsub_name(s) }
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

      def self.load(image_name : String?, data : Hash(String, YAML::Type)) : Service
        environment = (get_hash(data, "environment") || {} of String => String)
          .map { |k, v| {k, v.to_s} }
          .to_h

        volumes = (get_array(data, "volumes") || [] of YAML::Type).map(&.to_s)
        links = (get_array(data, "links") || [] of YAML::Type).map(&.to_s)

        new(
          image_name: image_name,
          environment: environment,
          volumes: volumes,
          links: links
        )
      end

      getter image_name, environment, volumes, links

      def initialize(@image_name : String?,
                     @environment : Hash(String, String),
                     @volumes : Array(String),
                     @links : Array(String))
      end

      # Merge the other scenario into this one, overwriting or appending to
      # fields as appropriate.
      def merge(other : Service?)
        if other.nil?
          self
        else
          Service.new(
            image_name: @image_name || other.image_name,
            environment: @environment.merge(other.environment),
            volumes: @volumes | other.volumes,
            links: @links | other.links
          )
        end
      end
    end
  end
end
