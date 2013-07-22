require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pry'

STDOUT.sync = true

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
puts "Configuration complete"
# name the domain and specify the retention period (in days)
domain = swf.domains['eops']
puts "Found domain, creating threads..."
# register an workflow type with the version id '1'
#workflow_type = domain.workflow_types.create('my-long-processes', '1',
#  :default_task_list => 'my-task-list',
#  :default_child_policy => :request_cancel,
#  :default_task_start_to_close_timeout => 3600,
#  :default_execution_start_to_close_timeout => 24 * 3600)

# register an activity type, with the version id '1'
#activity_type = domain.activity_types.create('do-something', '1', 
#  :default_task_list => 'my-task-list',
#  :default_task_heartbeat_timeout => 900,
#  :default_task_schedule_to_start_timeout => 60,
#  :default_task_schedule_to_close_timeout => 3660,
#  :default_task_start_to_close_timeout => 3600)

task_list = 'my-task-list'

activity_type = domain.activity_types.first
workflow_type = domain.workflow_types.first

if (activity_type.nil?) 
  puts "failed to find activity type" 
else
  puts "found activity type #{activity_type.name}"
end
if (workflow_type.nil?) 
  puts "failed to find workflow type" 
else
  puts "found workflow type #{workflow_type.name}"
end


threads = []

threads << Thread.new {
  while true
    workflow_execution = workflow_type.start_execution :input => 'input to workflow execution', :task_list => task_list
    puts "WF_EXEC_GEN: #{workflow_execution.to_json}"
    sleep 20
  end
  puts "WF_EXEC_GEN: exiting..."
}


#workflow_execution.workflow_id => "5abbdd75-70c7-4af3-a324-742cd29267c2"
#workflow_execution.run_id => "325a8c34-d133-479e-9ecf-5a61286d165f"


threads << Thread.new {
  puts "DECISION: Deciding and working..."
  # poll for decision tasks from task_last
  domain.decision_tasks.poll(task_list) do |task|
    puts "DECISION: Found decision tasks..."
    # investigate new events and make decisions
    task.new_events.each do |event|
      puts "DECISION: #{event.to_json}"
      puts "DECISION: Processing #{event.name}"
      
      case event.event_type
      when 'WorkflowExecutionStarted'
        puts "DECISION: Execution started of #{task.name}"
        task.schedule_activity_task activity_type, :input => 'abc xyz'
      when 'ActivityTaskCompleted'
        puts "DECISION: Activity completed of #{task.name}"
        task.complete_workflow_execution :result => event.attributes.result
        breakout = true
      when 'ScheduleActivityTaskFailed'
        puts "DECISION: Schedule Activity Task Failed because: #{event.cause}"
      when 'DecisionTaskScheduled'
        puts "DECISION: Decision task scheduled."
      when 'DecisionTaskStarted'
        puts "DECISION: Decision task started"
      when 'DecisionTaskCompleted'
        puts "DECISION: Decision task completed: #{event.name}"
      else
        puts "DECISION: didn't know what to do with #{event.event_type}"
      end
    end
  end # decision task is completed here
  puts "DECISION: exiting..."
}


threads << Thread.new {
  sleep 15

  puts "WORKER: Polling for activity tasks on list #{task_list}..."
  # poll task_list for activities
  domain.activity_tasks.poll(task_list) do |task|
    puts "WORKER: #{task.to_json}"
    puts "WORKER: Processing task #{task.activity_type.name}"
    begin

      # do stuff ...

      task.record_heartbeat! :details => '25%'

      # do more stuff ...

      task.record_heartbeat! :details => '50%'

      # do more stuff ...

      task.record_heartbeat! :details => '75%'

      # do more stuff ...

      task.complete!

    rescue ActivityTask::CancelRequestedError
      # cleanup after ourselves
      task.cancel!
    end
    puts "WORKER: Task processed"
  end
  puts "WORKER: exiting..."
}

threads.each { |aThread|  aThread.join }