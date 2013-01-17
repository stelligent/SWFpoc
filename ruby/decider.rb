require 'rubygems'
require 'yaml'
require 'aws-sdk'

config = {
 "access_key_id" => "",
 "secret_access_key" => ""
}

AWS.config(config)

swf = AWS::SimpleWorkflow.new

# name the domain and specify the retention period (in days)
#domain = swf.domains.create("eops-swf-#{Time.new.to_i}", 1)
#puts "Created domain: #{domain}"

eops = nil 
swf.domains.each do |domain|
    if domain.name == "eops-swf-1357946310"
        eops = domain 
    end
end

if (eops.nil?)
    exit
end

puts "Found eops domain"

# register an workflow type with the version id '1'
#workflow_type = eops.workflow_types.create('CreateTargetEnvironment', '1',
#  :default_task_list => 'job-task-list',
#  :default_child_policy => :request_cancel,
#  :default_task_start_to_close_timeout => 3600,
#  :default_execution_start_to_close_timeout => 24 * 3600)
#puts "Created workflow: #{workflow_type}"

# register an activity type, with the version id '1'

#activity_type = eops.activity_types.create('run-build-step', '1', 
#  :default_task_list => 'job-task-list',
#  :default_task_heartbeat_timeout => 900,
#  :default_task_schedule_to_start_timeout => 60,
#  :default_task_schedule_to_close_timeout => 3660,
#  :default_task_start_to_close_timeout => 3600)
#puts "Created activity #{activity_type}"

activity_type = eops.activity_types.first

puts "polling for decision tasks..."
# poll for decision tasks from 'job-task-list'
eops.decision_tasks.poll('job-task-list') do |task|

  # investigate new events and make decisions
  task.new_events.each do |event|
    begin
      case event.event_type
      when 'WorkflowExecutionStarted'
        puts "run-build-step"
        task.schedule_activity_task activity_type, :input => "input from decision task"
      when 'ActivityTaskCompleted'
        puts "ActivityTaskCompleted"
        task.complete_workflow_execution :result => event.attributes.result
      end
    rescue
      puts "#{$!}"
    end
  end

end # decision task is completed here