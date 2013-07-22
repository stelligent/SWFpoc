require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pry'
require './lib/swf-shared.rb'

STDOUT.sync = true

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


log "WORKER: Polling for activity tasks on list #{task_list}..."
# poll task_list for activities
domain.activity_tasks.poll(task_list) do |task|
  runid = task.workflow_execution.run_id

  log "WORKER: #{runid} Processing task #{task.activity_type.name}"
  begin

    log "WORKER: Executing command #{task.input}"
    `#{task.input}`

    # do stuff ...
    sleep 5
    task.record_heartbeat! :details => '25%'

    # do more stuff ...
    sleep 5
    task.record_heartbeat! :details => '50%'

    # do more stuff ...
    sleep 5
    task.record_heartbeat! :details => '75%'

    # do more stuff ...
    sleep 5
    task.complete!

  rescue ActivityTask::CancelRequestedError
    # cleanup after ourselves
    log "WORKER: Error occured"
    task.cancel!
  end
  log "WORKER: #{runid} Task processed"
end
log "WORKER: exiting..."
