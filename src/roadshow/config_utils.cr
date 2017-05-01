module Roadshow
  # Utility methods to make working with YAML less horrible.
  module ConfigUtils
    private def get_string(hash : Hash(K, YAML::Type), key : K) : String? forall K
      if hash.has_key?(key) && (value = hash[key]).is_a?(String)
        value
      end
    end

    private def get_string!(hash : Hash(K, YAML::Type), key : K) : String forall K
      get_string(hash, key) ||
        raise InvalidConfig.new("Missing required string `#{key}`")
    end

    private def get_hash(hash : Hash(K, YAML::Type), key : K) : Hash(String, YAML::Type)? forall K
      if hash.has_key?(key) && (value = hash[key]).is_a?(Hash)
        # For some reason (bug?) `to_h` doesn't work here, so we have to write
        # the `each_with_object` invocation ourselves.
        value.each_with_object(Hash(String, YAML::Type).new) do |(k, v), h|
          h[k.to_s] = v
        end
      end
    end

    private def get_hash!(hash : Hash(K, YAML::Type), key : K) : Hash(String, YAML::Type) forall K
      get_hash(hash, key) ||
        raise InvalidConfig.new("Missing required hash `#{key}`")
    end

    private def get_array(hash : Hash(K, YAML::Type), key : K) : Array(YAML::Type)? forall K
      if hash.has_key?(key) && (value = hash[key]).is_a?(Array)
        value
      end
    end

    private def get_array!(hash : Hash(K, YAML::Type), key : K) : Array(YAML::Type) forall K
      get_array(hash, key) ||
        raise InvalidConfig.new("Missing required array `#{key}`")
    end
  end
end
