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


log "DECISION: Deciding and working..."
# poll for decision tasks from task_last
domain.decision_tasks.poll(task_list) do |task|
  # investigate new events and make decisions
  log "PROCESSING TASK"
  task.new_events.each do |event|
    log "DECISION: PROCESSING EVENT"
    
    
    runid = task.workflow_execution.run_id

    case event.event_type
    when 'WorkflowExecutionStarted'
      log "DECISION: Execution started"
      task.schedule_activity_task activity_type, :input => event.attributes[:input]
    when 'ActivityTaskCompleted'
      log "DECISION: Activity completed"
      task.complete_workflow_execution# :result => event.attributes.result
    when 'ScheduleActivityTaskFailed'
      log "DECISION: Schedule Activity Task Failed because: #{event.cause}"
    when 'DecisionTaskScheduled'
      log "DECISION: Decision task scheduled."
    when 'DecisionTaskStarted'
      log "DECISION: Decision task started"
    when 'DecisionTaskCompleted'
      log "DECISION: Decision task completed"
    when 'ActivityTaskScheduled'
      log "DECISION: Activity Task scheduled"
    when 'ActivityTaskStarted'
      log "DECISION: Activity Task Started"
    when 'ActivityTaskFailed'
      log "DECISION: Activity Task Failed!!"
    else
      log "DECISION: didn't know what to do with #{event.event_type}"
    end
    log "DECISION: EVENT PROCESSED"
  end
  log "TASK PROCESSED"
end # decision task is completed here
log "DECISION: exiting..."
