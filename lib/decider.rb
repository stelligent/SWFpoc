require 'rubygems'
require 'yaml'
require 'aws-sdk'

class Decider

  def init(swf, name)
    eops = nil 
    swf.domains.each do |domain|
      if domain.name.eql? name
        eops = domain 
      end
    end

    if (eops.nil?)
      throw "Couldn't find domain!"
    end
    return eops
  end

  def poll(domain)
    # poll for decision tasks from 'job-task-list'
    domain.decision_tasks.poll('job-task-list') do |task|
      # investigate new events and make decisions
      activity_type = domain.activity_types.first
      task.new_events.each do |event|
        begin
          case event.event_type
          when 'WorkflowExecutionStarted'
            task.schedule_activity_task activity_type, :input => "input from decision task"
          when 'ActivityTaskCompleted'
            task.complete_workflow_execution :result => event.attributes.result
          end
        rescue
          puts "#{$!}"
        end
      end
    end
  end
end
