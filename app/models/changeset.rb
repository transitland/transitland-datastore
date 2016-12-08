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

  has_many :stop_platforms_created_or_updated, class_name: 'StopPlatform', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :stop_platforms_destroyed, class_name: 'StopPlatform', foreign_key: 'destroyed_in_changeset_id'

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
          entity.class.name.camelize(:lower) => entity.as_change(sticky: sticky?).as_json.compact
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

  def import?
    !!self.imported_from_feed && !!self.imported_from_feed_version
  end

  def sticky?
    import? && self.imported_from_feed.feed_version_imports.size > 1
  end

  def issues_unresolved(resolving_issues, changeset_issues)
    changeset_issues.map { |c| resolving_issues.map { |r| r if c.equivalent?(r) } }.flatten.compact
  end

  def check_quality
    gqc = QualityCheck::GeometryQualityCheck.new(changeset: self)
    shqc = QualityCheck::StationHierarchyQualityCheck.new(changeset: self)
    issues = []
    issues += gqc.check
    issues += shqc.check
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
    old_issues_to_deprecate = Set.new

    unless self.stops_created_or_updated.empty?
      self.stops_created_or_updated.each do |stop|
        operators_to_update_convex_hull.merge(OperatorServingStop.where(stop: stop).map(&:operator))
      end
      rsps_to_update_distances.merge(RouteStopPattern.with_stops(self.stops_created_or_updated.map(&:onestop_id).join(',')))

      operators_to_update_convex_hull.each { |operator|
        operator.geometry = operator.recompute_convex_hull_around_stops

        old_issues_to_deprecate.merge(Issue.issues_of_entity(operator, entity_attributes: ["geometry"]))
        operator.update_making_history(changeset: self)
      }
    end

    # Recompute and update the Route model representative geometry
    route_rsps = {}
    self.route_stop_patterns_created_or_updated.each do |rsp|
      route_rsps[rsp.route] ||= Set.new
      route_rsps[rsp.route] << rsp
    end
    route_rsps.each_pair do |route, rsps|
      representative_rsps = Route.representative_geometry(route, rsps || [])
      Route.geometry_from_rsps(route, representative_rsps)
      route.update_making_history(changeset: self)
    end

    # Recompute and update RouteStopPattern distances and associated ScheduleStopPairs
    rsps_to_update_distances.merge(self.route_stop_patterns_created_or_updated)
    log "Calculating distances" unless rsps_to_update_distances.empty?
    rsps_to_update_distances.each { |rsp|
      old_issues_to_deprecate.merge(Issue.issues_of_entity(rsp, entity_attributes: ["stop_distances"]))

      begin
        rsp.update_making_history(changeset: self, new_attrs: { stop_distances: rsp.calculate_distances })
      rescue StandardError
        log "Could not calculate distances for Route Stop Pattern: #{rsp.onestop_id}"
        rsp.update_making_history(changeset: self, new_attrs: { stop_distances: rsp.fallback_distances })
      end

      rsp.ordered_ssp_trip_chunks { |trip_chunk|
        trip_chunk.each_with_index do |ssp, i|
          ssp.update_column(:origin_dist_traveled, rsp.stop_distances[i])
          ssp.update_column(:destination_dist_traveled, rsp.stop_distances[i+1])
        end
      }
    }
    #second item mainly for testing
    [old_issues_to_deprecate, [rsps_to_update_distances.size, operators_to_update_convex_hull.size]]
  end

  def cycle_issues(issues_changeset_is_resolving, new_issues_created_by_changeset, old_issues_to_deprecate)
    # check if a changeset's specified issuesResolved, if any, are actually resolved.
    unresolved_issues = issues_unresolved(issues_changeset_is_resolving, new_issues_created_by_changeset)
    if (unresolved_issues.empty?)
      issues_changeset_is_resolving.each { |issue| issue.update!({ open: false, resolved_by_changeset: self}) }

      new_issues_created_by_changeset.each(&:save!)

      # need to make sure the right instances of the resolving issues -
      # those containing open=false and resolved_by_changeset - are added
      # to old_issues_to_deprecate so they are logged as "resolved" during deprecation,
      # before the transaction is complete.
      old_issues_to_deprecate.keep_if { |i|
          !issues_changeset_is_resolving.map(&:id).include?(i.id)
        }.merge(issues_changeset_is_resolving)
        .each(&:deprecate)
    else
      message = unresolved_issues.map { |issue| "Issue #{issue.id} was not resolved." }.join(" ")
      logger.error "Error applying Changeset #{self.id}: #{message}"
      raise Changeset::Error.new(changeset: self, message: message)
    end
  end

  def create_feed_entity_associations
    if import?
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
  end

  def apply!
    fail Changeset::Error.new(changeset: self, message: 'has already been applied.') if applied
    new_issues_created_by_changeset = []
    old_issues_to_deprecate = Set.new

    Changeset.transaction do
      begin
        # Apply ChangePayloads, collect issues
        issues_changeset_is_resolving = []
        change_payloads.each do |change_payload|
          payload_issues_changeset_is_resolving, payload_old_issues_to_deprecate = change_payload.apply!
          issues_changeset_is_resolving += payload_issues_changeset_is_resolving
          old_issues_to_deprecate.merge(payload_old_issues_to_deprecate)
        end
        self.update(applied: true, applied_at: Time.now)

        create_feed_entity_associations

        # Update attributes that derive from attributes between models
        # This needs to be done before quality checks. Only on import.
        unless import?
          computed_attrs_old_issues_to_deprecate, sizes = update_computed_attributes
          old_issues_to_deprecate.merge(computed_attrs_old_issues_to_deprecate)
        end

        # Check for new issues on this changeset
        new_issues_created_by_changeset = check_quality

        # save new issues; deprecate old issues; resolve changeset-specified issues
        cycle_issues(issues_changeset_is_resolving, new_issues_created_by_changeset, old_issues_to_deprecate)

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
    return true, new_issues_created_by_changeset
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
