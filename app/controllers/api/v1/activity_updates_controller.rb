class Api::V1::ActivityUpdatesController < Api::V1::BaseApiController
  HOURS = 7 * 24

  def index
    @activity_updates = Rails.cache.fetch("activity_updates", expires_in: 1.minute) do
      ActivityUpdates.updates_since(HOURS.hours.ago)
    end

    if params[:feed].present?
      feed_onestop_ids = params[:feed].split(',')
      @activity_updates.select! do |update|
        update[:entity_type] == 'feed' && feed_onestop_ids.include?(update[:entity_id])
      end
    end
    if params[:changeset].present?
      changeset_ids = params[:changeset].split(',').map(&:to_i)
      @activity_updates.select! do |update|
        update[:entity_type] == 'changeset' && changeset_ids.include?(update[:entity_id])
      end
    end

    respond_to do |format|
      format.json { render json: {activity_updates: @activity_updates} }
      format.rss { render layout: false }
    end
  end
end
