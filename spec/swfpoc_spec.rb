require_relative '../lib/decider'
require_relative '../lib/worker'
require_relative '../lib/setup'

require 'aws-sdk'


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

#setup

describe Decider, "init" do
    it "finds the eops domain" do
        domain = double("domain")
        domain.should_receive(:name).and_return("eops")

        swf = double("swf")
        swf.should_receive(:domains).and_return([domain])

        decider = Decider.new()
        domain = decider.init(swf, "eops")
        domain.should_not be_nil
    end

    it "polls for new events" do
        domain = double("domain")
        task_list = double("decision_tasks")
        task_list.should_receive(:poll).and_return([])
        domain.should_receive(:decision_tasks).and_return(task_list)
        decider = Decider.new()
        decider.poll(domain)
    end
end

describe Worker, "init" do
    it "finds the eops domain" do
        domain = double("domain")
        domain.should_receive(:name).and_return("eops")

        swf = double("swf")
        swf.should_receive(:domains).and_return([domain])

        decider = Decider.new()
        domain = decider.init(swf, "eops")
        domain.should_not be_nil
    end
end