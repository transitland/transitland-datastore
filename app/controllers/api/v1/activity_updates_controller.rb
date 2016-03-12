class Api::V1::ActivityUpdatesController < Api::V1::BaseApiController
  HOURS = 7 * 24

  def index
    @activity_updates = Rails.cache.fetch("activity_updates", expires_in: 1.minute) do
      ActivityUpdates.updates_since(HOURS.hours.ago)
    end

    if params[:feed].present?
      @activity_updates.select! do |update|
        update[:entity_type] == 'feed' && update[:entity_id] == params[:feed]
      end
    end
    if params[:changeset].present?
      @activity_updates.select! do |update|
        update[:entity_type] == 'changeset' && update[:entity_id] == params[:changeset].to_i
      end
    end

    respond_to do |format|
      format.json { render json: @activity_updates }
      format.rss { render layout: false }
    end
  end
end
