require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pry'

STDOUT.sync = true

def log(message)
  timestamp = Time.now.strftime "%H:%M:%S"
  puts "#{timestamp}: #{message}"
end

def configure(config_file)
  unless File.exist?(config_file)
    puts <<END
  To run the samples, put your credentials in config.yml as follows:

  access_key_id: YOUR_ACCESS_KEY_ID
  secret_access_key: YOUR_SECRET_ACCESS_KEY

END
    exit 1
  end

  config = YAML.load(File.read(config_file))

  unless config.kind_of?(Hash)
    puts <<END
  config.yml is formatted incorrectly.  Please use the following format:

  access_key_id: YOUR_ACCESS_KEY_ID
  secret_access_key: YOUR_SECRET_ACCESS_KEY

END
    exit 1
  end

  AWS.config(config)
end

configure '/Users/jonny/Desktop/SWFpoc/config/aws.yml'

swf = AWS::SimpleWorkflow.new
log "Configuration complete"
# name the domain and specify the retention period (in days)
domain = swf.domains['eops']
task_list = 'my-task-list'

activity_type = domain.activity_types.first
workflow_type = domain.workflow_types.first

if (activity_type.nil?) 
  log "failed to find activity type" 
else
  log "found activity type #{activity_type.name}"
end
if (workflow_type.nil?) 
  log "failed to find workflow type" 
else
  log "found workflow type #{workflow_type.name}"
end


  while true
    workflow_execution = workflow_type.start_execution :input => 'input to workflow execution', :task_list => task_list
    log "WF_EXEC_GEN: #{workflow_execution.run_id}"
    sleep 60
  end
  log "WF_EXEC_GEN: exiting..."
