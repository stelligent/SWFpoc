require 'rubygems'
require 'yaml'
require 'aws-sdk'


class Worker
  def init(swf, name)
    eops = nil 
    swf.domains.each do |domain|
      if domain.name.eql? name
        eops = domain 
      end
    end

    if (eops.nil?)
      throw "Couldn't find domain!"
    else
      puts "Found eops domain"
    end
    return eops
  end

  def find_work(domain)
    domain.activity_tasks.poll('job-task-list') do |activity_task|
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
  end
end