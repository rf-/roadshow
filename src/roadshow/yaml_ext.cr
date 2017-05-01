# HACK: The YAML library is failing to quote some strings that need to be
# quoted, specifically numeric strings and strings containing colons.
class YAML::Builder
  def scalar(value)
    string = value.to_s

    style = string =~ /^\d+$|:/ ? LibYAML::ScalarStyle::DOUBLE_QUOTED : LibYAML::ScalarStyle::ANY

    emit scalar, nil, nil, string, string.bytesize, 1, 1, style
  end
end
