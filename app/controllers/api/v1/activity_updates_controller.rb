class Api::V1::ActivityUpdatesController < Api::V1::BaseApiController
  def index
    hours = params[:hours] || (24 * 7)

    raise ArgumentError, "hours must be positive" if hours < 0

    @activity_updates = ActivityUpdates.updates_since(hours.hours.ago)

    respond_to do |format|
      format.json { render json: @activity_updates }
      format.rss { render layout: false }
    end
  end
end
