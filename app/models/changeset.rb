# == Schema Information
#
# Table name: changesets
#
#  id              :integer          not null, primary key
#  notes           :text
#  applied         :boolean
#  applied_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :integer
#  feed_id         :integer
#  feed_version_id :integer
#
# Indexes
#
#  index_changesets_on_feed_id          (feed_id)
#  index_changesets_on_feed_version_id  (feed_version_id)
#  index_changesets_on_user_id          (user_id)
#

class Changeset < ActiveRecord::Base
  class Error < StandardError
    attr_accessor :changeset, :message, :backtrace, :payload

    def initialize(changeset: nil, payload: {}, message: '', backtrace: [])
      @changeset = changeset
      @payload = payload
      @message = message
      @backtrace = backtrace
    end

    def to_s
      "Changeset::Error #{@message}"
    end
  end

  CHANGE_PAYLOAD_MAX_ENTITIES = Figaro.env.feed_eater_change_payload_max_entities.try(:to_i) || 1_000

  include CanBeSerializedToCsv

  has_many :feeds_created_or_updated, class_name: 'Feed', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :feeds_destroyed, class_name: 'OldFeed', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_in_feed_created_or_updated, class_name: 'OperatorInFeed', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_in_feed_destroyed, class_name: 'OldOperatorInFeed', foreign_key: 'destroyed_in_changeset_id'

  has_many :stops_created_or_updated, class_name: 'Stop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :stops_destroyed, class_name: 'OldStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_created_or_updated, class_name: 'Operator', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_destroyed, class_name: 'OldOperator', foreign_key: 'destroyed_in_changeset_id'

  has_many :routes_created_or_updated, class_name: 'Route', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :routes_destroyed, class_name: 'OldRoute', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_serving_stop_created_or_updated, class_name: 'OperatorServingStop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_serving_stop_destroyed, class_name: 'OldOperatorServingStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :routes_serving_stop_created_or_updated, class_name: 'RouteServingStop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :routes_serving_stop_destroyed, class_name: 'OldRouteServingStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :change_payloads, -> { order "created_at ASC" }, dependent: :destroy

  has_many :schedule_stop_pairs_created_or_updated, class_name: 'ScheduleStopPair', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :schedule_stop_pairs_destroyed, class_name: 'OldScheduleStopPair', foreign_key: 'destroyed_in_changeset_id'

  has_many :route_stop_patterns_created_or_updated, class_name: 'RouteStopPattern', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :route_stop_patterns_destroyed, class_name: 'OldRouteStopPattern', foreign_key: 'destroyed_in_changeset_id'

  belongs_to :user, autosave: true
  belongs_to :imported_from_feed, class_name: 'Feed', foreign_key: 'feed_id'
  belongs_to :imported_from_feed_version, class_name: 'FeedVersion', foreign_key: 'feed_version_id'

  def set_user_by_params(user_params)
    self.user = User.find_or_initialize_by(email: user_params[:email].downcase)
    self.user.update_attributes(user_params)
    self.user.user_type ||= nil # for some reason, Enumerize needs to see a value
  end

  after_initialize :set_default_values
  after_create :creation_email

  def entities_created_or_updated(&block)
    # Pass &block to find_each for each kind of entity.
    feeds_created_or_updated.find_each(&block)
    operators_in_feed_created_or_updated.find_each(&block)
    stops_created_or_updated.find_each(&block)
    operators_created_or_updated.find_each(&block)
    routes_created_or_updated.find_each(&block)
    route_stop_patterns_created_or_updated.find_each(&block)
  end

  def relations_created_or_updated(&block)
    operators_serving_stop_created_or_updated.find_each(&block)
    routes_serving_stop_created_or_updated.find_each(&block)
  end

  def entities_destroyed(&block)
    feeds_destroyed.find_each(&block)
    operators_destroyed.find_each(&block)
    stops_destroyed.find_each(&block)
    operators_destroyed.find_each(&block)
    routes_destroyed.find_each(&block)
    route_stop_patterns_destroyed.find_each(&block)
  end

  def relations_destroyed(&block)
    operators_serving_stop_destroyed.find_each(&block)
    routes_serving_stop_destroyed.find_each(&block)
  end

  def trial_succeeds?
    trial_succeeds = false
    issues = []
    Changeset.transaction do
      begin
        trial_succeeds, issues = apply!
      rescue Exception => e
        raise ActiveRecord::Rollback
      else
        raise ActiveRecord::Rollback
      end
    end
    self.reload
    return trial_succeeds, issues
  end

  def create_change_payloads(entities)
    entities.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
      changes = chunk.map do |entity|
        {
          :action => :createUpdate,
          entity.class.name.camelize(:lower) => entity.as_change.as_json.compact
        }
      end
      payload = {changes: changes}
      begin
        change_payload = self.change_payloads.create!(payload: payload)
      rescue StandardError => e
        fail Changeset::Error.new(
          changeset: self,
          payload: payload,
          message: e.message,
          backtrace: e.backtrace
        )
      end
    end
  end

  def destroy_all_change_payloads
    # Destroy change payloads
    change_payloads.destroy_all
  end

  def issues_unresolved(resolving_issues, changeset_issues)
    changeset_issues.map { |c| resolving_issues.map { |r| r if c.equivalent?(r) } }.flatten.compact
  end

  def check_quality
    gqc = QualityCheck::GeometryQualityCheck.new(changeset: self)
    issues = []
    issues += gqc.check
    issues
  end

  def update_computed_attributes
    # This method updates the changeset's entity attributes that are computed/derived from the attribute data
    # of multiple entity types. For example, here RouteStopPatterns will have to have their stop distances recomputed
    # using both the RouteStopPattern and its stop_pattern Stops' geometries. Operators have their convex hulls
    # recomputed from the Stops it serves.
    #
    # Ideally we would like to define methods at the model level (that would be the first place to put new
    # recomputed attribute functionality if possible) but the need to avoid duplicate recomputation on entities of update
    # changesets complicates this. E.g, We don't want to recompute the stop_distances of one RouteStopPattern
    # multiple times if there are multiple Stops of that RouteStopPattern in the changeset.
    rsps_to_update_distances = Set.new
    operators_to_update_convex_hull = Set.new

    unless self.stops_created_or_updated.empty?
      self.stops_created_or_updated.each do |stop|
        operators_to_update_convex_hull.merge(OperatorServingStop.where(stop: stop).map(&:operator))
      end
      rsps_to_update_distances.merge(RouteStopPattern.with_stops(self.stops_created_or_updated.map(&:onestop_id).join(',')))

      operators_to_update_convex_hull.each { |operator|
        operator.geometry = operator.recompute_convex_hull_around_stops
        operator.update_making_history(changeset: self)
      }
    end

    rsps_to_update_distances.merge(self.route_stop_patterns_created_or_updated)
    rsps_to_update_distances.each { |rsp|
      rsp.update_making_history(changeset: self, new_attrs: { stop_distances: rsp.calculate_distances })
      rsp.ordered_ssp_trip_chunks { |trip_chunk|
        trip_chunk.each_with_index do |ssp, i|
          ssp.update_column(:origin_dist_traveled, rsp.stop_distances[i])
          ssp.update_column(:destination_dist_traveled, rsp.stop_distances[i+1])
        end
      }
    }
    #mainly for testing
    [rsps_to_update_distances.size, operators_to_update_convex_hull.size]
  end

  def apply!
    fail Changeset::Error.new(changeset: self, message: 'has already been applied.') if applied
    changeset_issues = nil

    Changeset.transaction do
      begin
        # Apply ChangePayloads, collect issues
        resolving_issues = []
        change_payloads.each do |change_payload|
          resolving_issues += change_payload.apply!
        end
        self.update(applied: true, applied_at: Time.now)

        # Create any feed-entity associations
        if self.imported_from_feed && self.imported_from_feed_version
          eiff_batch = []
          self.entities_created_or_updated do |entity|
            eiff_batch << entity
              .entities_imported_from_feed
              .new(feed: self.imported_from_feed, feed_version: self.imported_from_feed_version)
            if eiff_batch.size >= 1000
              EntityImportedFromFeed.import eiff_batch
              eiff_batch = []
            end
          end
          EntityImportedFromFeed.import eiff_batch
        end

        # Update computed properties
        update_computed_attributes unless self.imported_from_feed && self.imported_from_feed_version

        # Check for issues
        changeset_issues = check_quality
        unresolved_issues = issues_unresolved(resolving_issues, changeset_issues)
        if (unresolved_issues.empty?)
          resolving_issues.each { |issue| issue.update!({ open: false, resolved_by_changeset: self}) }
          changeset_issues.each(&:save!)
          # Temporarily disabling deactivation for non-import changesets until faster implementation
          # or all-async changesets
          Issue.bulk_deactivate if self.imported_from_feed && self.imported_from_feed_version
          resolving_issues.each {|issue|
            log("Deprecating issue: #{issue.as_json(include: [:entities_with_issues])}")
            EntityWithIssues.delete issue.entities_with_issues
            issue.delete
          }
        else
          message = unresolved_issues.map { |issue| "Issue #{issue.id} was not resolved." }.join(" ")
          logger.error "Error applying Changeset #{self.id}: " + message
          raise Changeset::Error.new(changeset: self, message: message)
        end

      rescue StandardError => error
        logger.error "Error applying Changeset #{self.id}: #{error.message}"
        logger.error error.backtrace
        raise Changeset::Error.new(changeset: self, message: error.message, backtrace: error.backtrace)
      end
    end

    unless Figaro.env.send_changeset_emails_to_users.presence == 'false'
      if self.user && self.user.email.present? && !self.user.admin
        ChangesetMailer.delay.application(self.id)
      end
    end
    # Now that the transaction is complete and has been committed,
    # we can do some async tasks like conflate stops with OSM...
    if Figaro.env.auto_conflate_stops_with_osm.present? &&
       Figaro.env.auto_conflate_stops_with_osm == 'true' &&
       self.stops_created_or_updated.count > 0
      ConflateStopsWithOsmWorker.perform_async(self.stops_created_or_updated.map(&:id))
    end
    # ...and fetching any new feeds
    if Figaro.env.auto_fetch_feed_version.presence == 'true'
      FeedFetcherService.fetch_these_feeds_async(self.feeds_created_or_updated)
    end
    return true, changeset_issues
  end

  def revert!
    if applied
      # TODO: write it
      raise Changeset::Error.new(changeset: self, message: "cannot revert. This functionality doesn't exist yet.")
    else
      raise Changeset::Error.new(changeset: self, message: 'cannot revert. This changeset has not been applied yet.')
    end
  end

  def bounding_box
    # TODO: write it
  end

  def payload=(changeset)
    change_payloads.build payload: changeset
  end

  private

  def set_default_values
    if self.new_record?
      self.applied ||= false
    end
  end

  def creation_email
    unless Figaro.env.send_changeset_emails_to_users.presence == 'false'
      if self.user && self.user.email.present? && !self.user.admin
        ChangesetMailer.delay.creation(self.id)
      end
    end
  end

end
