class Api::V1::GTFSEntityController < Api::V1::BaseApiController
    include JsonCollectionPagination
    include AllowFiltering

    def self.model
      fail Exception.new("Abstract method")
    end
  
    def index
      index_query
      index_includes
      respond_to do |format|
        format.json { render paginated_json_collection(@collection).merge({ scope: render_scope, each_serializer: render_serializer }) }
        format.geojson { render paginated_geojson_collection(@collection).merge({ scope: render_scope }) }
      end
    end
  
    def show
      set_model
      respond_to do |format|
        format.json { render json: @model, serializer: render_serializer, scope: render_scope }
        format.geojson { render json: @model, serializer: GeoJSONSerializer }
      end
    end
  
    private
  
    def index_query
      # Entity
      @collection = (self.class.model).where('')
  
      # Geometry
      index_query_geometry
  
      # Imported From Feed
      if params[:imported_from_feed].present?
        @collection = @collection.where_imported_from_feed(Feed.find_by_onestop_id!(params[:imported_from_feed]))
      end
      if params[:imported_from_feed_version].present?
        @collection = @collection.where_imported_from_feed_version(FeedVersion.find_by!(sha1: params[:imported_from_feed_version]))
      end
      if params[:imported_from_active_feed_version].presence.eql?("true")
        @collection = @collection.where_imported_from_active_feed_version
      end
    end
  
    def index_query_geometry
      if [params[:lat], params[:lon]].map(&:present?).all?
        point = (self.class.model)::GEOFACTORY.point(params[:lon], params[:lat])
        r = params[:r] || 100 # meters TODO: move this to a more logical place
        @collection = @collection.where{st_dwithin(geometry, point, r)}.order{st_distance(geometry, point)}
      end
      if params[:bbox].present?
        @collection = @collection.geometry_within_bbox(params[:bbox])
      end
    end
  
    def index_includes
      scope = render_scope
      @collection = @collection.includes{[imported_from_feeds, imported_from_feed_versions]} if scope[:imported_from_feeds]
      @collection = @collection.includes(:issues) if scope[:issues]
    end
  
    def render_scope
      # Get the list of include and exclude options
      incl = {
        geometry: true,
        imported_from_feeds: false,
        id: false
      }
      AllowFiltering.param_as_array(params, :include).map(&:to_sym).each { |i| incl[i] = true }
      AllowFiltering.param_as_array(params, :exclude).map(&:to_sym).each { |i| incl[i] = false }
      return incl
    end
  
    def render_serializer
      ActiveModel::Serializer.serializer_for(self.class.model)
    end
  
    def paginated_json_collection(collection)
      result = super
      result[:root] = self.class.model.model_name.collection.sub('gtfs_','')
      result
    end

    def set_model
      @model = (self.class.model).find(params[:id])
    end
  
    def query_params
      # Allowed query parameters - and documentation
      super.merge({
        lat: {
            desc: "Latitude",
            type: "float"
        },
        lon: {
            desc: "Longitude",
            type: "float"
        },
        r: {
            desc: "Radius, in meters",
            type: "float"
        },
        bbox: {
            desc: "Bounding box",
            type: "bbox"
        },
        import_level: {
            desc: "Import level",
            type: "integer",
            array: true
        },
        gtfs_id: {
          desc: "Imported with GTFS ID",
          type: "string",
          array: true
        },
        imported_from_feed: {
            desc: "Imported from Feed",
            type: "onestop_id",
            array: true
        },
        imported_from_feed_version: {
            desc: "Imported from Feed Version",
            type: "sha1",
            array: true
        },
        imported_from_active_feed_version: {
            desc: "Imported from the current active Feed Version",
            type: "boolean"
        },
        include: {
            desc: "Include values",
            type: "enum",
            enum: ["geometry","imported_from_feeds"]
        },
        exclude: {
            desc: "Exclude values",
            type: "enum",
            enum: ["geometry","imported_from_feeds"]
        }
      })
    end
  end
  