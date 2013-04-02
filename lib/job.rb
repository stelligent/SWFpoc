require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pry'
require './lib/swf-shared.rb'

STDOUT.sync = true


configure '/Users/jonny/Desktop/SWFpoc/config/aws.yml'

swf = AWS::SimpleWorkflow.new
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

workflow_execution = workflow_type.start_execution :input => ARGV[0], :task_list => task_list
log "WF_EXEC_GEN: #{workflow_execution.run_id}"

while (not workflow_execution.closed?) do
  log workflow_execution.status
  sleep 5
end
log workflow_execution.status
log "exiting..."
