require 'rubygems'
require 'yaml'
require 'aws-sdk'

class Decider

  def init
    swf = AWS::SimpleWorkflow.new

    @eops = nil 
    swf.domains.each do |domain|
      if domain.name == "@eops-swf-1357946310"
        @eops = domain 
      end
    end

    if (@eops.nil?)
      throw "Couldn't find domain!"
    else
      puts "Found @eops domain"
    end
  end

  def poll
    puts "polling for decision tasks..."
    # poll for decision tasks from 'job-task-list'
    @eops.decision_tasks.poll('job-task-list') do |task|
    # investigate new events and make decisions

      activity_type = @eops.activity_types.first

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
    end
  end

end
