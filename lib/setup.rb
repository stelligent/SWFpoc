def usage_config
  puts <<USAGE
To run the samples, put your credentials in config.yml as follows:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

USAGE
  exit 1
end

def setup
  config_path = File.expand_path(File.dirname(__FILE__)+"/../config/aws.yml")
  unless File.exist?(config_path)
    usage_config
  end

  config = YAML.load(File.read(config_path))

  unless config.kind_of?(Hash)
    usage_config
  end

  AWS.config(config)
end
