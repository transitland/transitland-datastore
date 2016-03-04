class Api::V1::ActivityUpdatesController < Api::V1::BaseApiController
  HOURS = 7 * 24

  def index
    @activity_updates = Rails.cache.fetch("activity_updates", expires_in: 1.minute) do
      ActivityUpdates.updates_since(HOURS.hours.ago)
    end

    respond_to do |format|
      format.json { render json: @activity_updates }
      format.rss { render layout: false }
    end
  end
end
