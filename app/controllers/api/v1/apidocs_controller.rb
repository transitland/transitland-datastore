class Api::V1::ApidocsController < ApplicationController
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'

    info do
      key :version, '1.0.0'
      key :title, 'Transitland Datastore API'
      key :description, 'Consume and contribute open data for public-transit networks around the world.
                        The Datastore API powers the <a href="https://transit.land/feed-registry/">
                        Transitland Feed Registry</a>, the <a href="https://transit.land/playground/">
                        Transitland Playground</a> data explorer and downloader, the <a href="https://transit.land/dispatcher/">
                        Transitland Dispatcher</a> admin interface, and a variety of apps,
                        visualizations, and analyses created by Transitland collaborators.'.squish
      key :termsOfService, 'https://transit.land/terms/'
      # contact do
      #   key :url, 'https://transit.land/participate'
      #   key :email, 'transitland@mapzen.com'
      # end
    end
    key :schemes, [Figaro.env.transitland_datastore_host.split('://')[0]]
    key :host, Figaro.env.transitland_datastore_host.match(/:\/\/([^\/]+)/)[1]
    key :basePath, '/api/v1'
    key :consumes, ['application/json']
    key :produces, [
      'application/json',
      'application/vnd.geo+json',
      'text/csv'
    ]

    security_definition :api_auth_token do
      key :type, :apiKey
      key :name, :Authorization
      key :in, :header
    end

    # tags
    tag do
      key :name, 'changeset'
      key :description, 'Creating, editing, checking, and applying changesets'
      externalDocs do
        key :description, 'Learn more about routes'
        key :url, 'https://transit.land/documentation/datastore/changesets.html'
      end
    end
    tag do
      key :name, 'feed'
      key :description, 'Querying feeds, feed versions downloaded, and feed versions imported'
      externalDocs do
        key :description, 'Learn more about routes'
        key :url, 'https://transit.land/documentation/datastore/feeds.html'
      end
    end
    tag do
      key :name, 'stop'
      key :description, 'Querying stop locations'
      externalDocs do
        key :description, 'Learn more about stops'
        key :url, 'https://transit.land/documentation/datastore/stops.html'
      end
    end
    tag do
      key :name, 'route'
      key :description, 'Querying routes and the order in which they visit stop locations'
      externalDocs do
        key :description, 'Learn more about routes'
        key :url, 'https://transit.land/documentation/datastore/routes.html'
      end
    end
    tag do
      key :name, 'schedule'
      key :description, 'Querying service schedules'
      externalDocs do
        key :description, 'Learn more about service schedules'
        key :url, 'https://transit.land/documentation/datastore/schedule.html'
      end
    end
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CONTROLLERS = [
    FeedsController,
    FeedVersionsController,
    FeedVersionImportsController,
    OperatorsController,
    StopsController,
    RoutesController,
    RouteStopPatternsController,
    ScheduleStopPairsController,
    ChangesetsController,
    ChangePayloadsController,
    UsersController,
    WebhooksController
  ].freeze
  SWAGGERED_CONTROLLER_CONCERNS_WITH_PARAMETERS = [
    JsonCollectionPagination
  ].freeze
  SWAGGERED_MODELS = [
    Feed,
    FeedVersion,
    FeedVersionImport,
    Operator,
    Stop,
    Route,
    RouteStopPattern,
    ScheduleStopPair,
    Changeset,
    ChangePayload,
    User
  ].freeze
  SWAGGERED_CLASSES = SWAGGERED_CONTROLLERS + SWAGGERED_MODELS + [self]

  def index
    # TODO: add caching
    render json: swagger_json
  end

  private

  def swagger_json
    controller_concern_parameters_json = {}
    SWAGGERED_CONTROLLER_CONCERNS_WITH_PARAMETERS.each do |concern|
      controller_concern_parameters_json[concern.to_s.camelize(:lower)] = concern::SWAGGER_PARAMETERS
    end
    swagger_blocks_json = Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
    # swagger_blocks_json[:parameters] = controller_concern_parameters_json
    swagger_blocks_json
  end
end
