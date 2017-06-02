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
    respond_to do |format|
      format.json { render paginated_json_collection(@collection).merge({ scope: { embed_issues: AllowFiltering.to_boolean(params[:embed_issues]) } }) }
      format.geojson { render paginated_geojson_collection(@collection) }
      format.csv { return_downloadable_csv(@collection, 'feeds') }
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

  def index_includes
    @collection = @collection.includes{[
      changesets_imported_from_this_feed,
      active_feed_version,
      feed_versions
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
