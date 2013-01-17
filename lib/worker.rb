require 'rubygems'
require 'yaml'
require 'aws-sdk'

config = {
 "access_key_id" => "",
 "secret_access_key" => ""
}

AWS.config(config)

swf = AWS::SimpleWorkflow.new

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

eops.activity_tasks.poll('job-task-list') do |activity_task|
  case activity_task.activity_type.name
  when 'run-build-step' 
      begin
        puts activity_task.input
        activity_task.record_heartbeat! :details => 'workin\' it'
 
      rescue ActivityTask::CancelRequestedError
        # cleanup after ourselves
        activity_task.cancel!
      end
  else
    activity_task.fail! :reason => 'unknown activity task type'
  end
end