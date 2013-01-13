module RunStatusReport
  class RunStatusReporter < Chef::Handler

    def report
      Chef::Log.info "RunStatusReporter is running"
      node.set["is_failed"] = run_status.failed?
      node.set["is_success"] = run_status.success?
      node.set["backtrace"] = run_status.backtrace
      node.set["exception"] = run_status.exception
      node.set["formatted_exception"] = run_status.formatted_exception
      #node.set["all_resources"] = run_status.all_resources
      #node.set["updated_resources"] = run_status.updated_resources
      node.set["elapsed_time"] = run_status.elapsed_time
      node.set["start_time"] = run_status.start_time
      node.set["end_time"] = run_status.end_time
      #node.set["run_context"] = run_status.run_context
      node.save
      Chef::Log.info "RunStatusReporter completed"
    end
  end
end
