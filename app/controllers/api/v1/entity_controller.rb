class Api::V1::EntityController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  MODEL = nil

  def index
    index_query
    index_includes
    index_response
  end

  def index_collection_model
  end

  private

  def index_response
    scope = {
      embed_issues: AllowFiltering.to_boolean(params[:embed_issues])
    }
    respond_to do |format|
      format.json { render paginated_json_collection(@collection).merge({ scope: scope }) }
      format.geojson { render paginated_geojson_collection(@collection).merge({ scope: scope }) }
      format.csv { return_downloadable_csv(@collection, self.class::MODEL.name.underscore.pluralize) }
    end
  end

  def index_query
    # Entity
    @collection = (self.class::MODEL).where('')
    @collection = AllowFiltering.by_onestop_id(@collection, params)
    @collection = AllowFiltering.by_tag_keys_and_values(@collection, params)
    @collection = AllowFiltering.by_updated_since(@collection, params)
    @collection = AllowFiltering.by_attribute_array(@collection, params, :url, case_sensitive: true)

    # Geometry
    if [params[:lat], params[:lon]].map(&:present?).all?
      point = (self.class::MODEL)::GEOFACTORY.point(params[:lon], params[:lat])
      r = params[:r] || 100 # meters TODO: move this to a more logical place
      @collection = @collection.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
    end
    if params[:bbox].present?
      @collection = @collection.geometry_within_bbox(params[:bbox])
    end

    # Imported From Feed
    if params[:imported_from_feed].present?
      @collection = @collection.where_imported_from_feed(Feed.find_by_onestop_id(params[:imported_from_feed]))
    end
    if params[:imported_from_feed_version].present?
      @collection = @collection.where_imported_from_feed_version(FeedVersion.find_by!(sha1: params[:imported_from_feed_version]))
    end
    if params[:imported_from_active_feed_version].presence.eql?("true")
      @collection = @collection.where_imported_from_active_feed_version
    end
    if params[:imported_with_gtfs_id].present?
      @collection = @collection.where_imported_with_gtfs_id(params[:gtfs_id] || params[:imported_with_gtfs_id])
    end
    if params[:import_level].present?
      @collection = @collection.where_import_level(AllowFiltering.param_as_array(params, :import_level))
    end
  end

  def index_includes
    @collection = @collection.includes{[
      imported_from_feeds,
      imported_from_feed_versions,
    ]}
    @collection = @collection.includes(:issues) if AllowFiltering.to_boolean(params[:embed_issues])
  end

  def query_params
    params.slice(
      :onestop_id,
      :updated_since,
      :lat,
      :lon,
      :r,
      :bbox,
    )
  end
end
