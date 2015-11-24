module DatastoreAdmin
  class DashboardController < ApplicationController
    def main

    end

    def reset
      begin
        ResetDatastore.clear_enqueued_jobs if params[:clear_enqueued_jobs]
        ResetDatastore.destroy_feed_versions if params[:destroy_feed_versions]
        ResetDatastore.clear_cache if params[:clear_cache]
        ResetDatastore.truncate_database if params[:truncate_database]
      rescue
        flash[:error] = $!.message
      else
        messages = []
        messages << 'Successfully cleared enqueued jobs.' if params[:clear_enqueued_jobs]
        messages << 'Successfully destroyed feed versions.' if params[:destroy_feed_versions]
        messages << 'Successfully cleared cache.' if params[:clear_cache]
        messages << 'Successfully truncated database.' if params[:truncate_database]
        if messages.size > 0
          flash[:success] = messages.join(' ')
        else
          flash[:info] = "You didn't check any boxes, so I didn't do anything."
        end

        workers = Sidekiq::Workers.new
        if workers.size > 0
          flash[:warning] = "#{workers.size} worker(s) currently executing. You might want to truncate the database again, once they are complete."
        end
      end

      redirect_to :root
    end
  end
end
