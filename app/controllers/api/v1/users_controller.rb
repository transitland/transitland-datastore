class Api::V1::UsersController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_filter :require_api_auth_token
  before_action :set_user, only: [:show, :update, :destroy]

  # GET /users
  include Swagger::Blocks
  swagger_path '/users' do
    operation :get do
      key :tags, ['admin']
      key :name, :tags
      key :summary, 'Returns all users with filtering'
      key :description, 'Requires API authentication.'
      key :produces, ['application/json']
      response 200 do
        # key :description, 'stop response'
        schema do
          key :type, :array
          items do
            key :'$ref', :User
          end
        end
      end
    end
  end
  def index
    @users = User.where('').include{changesets}

    @users = AllowFiltering.by_primary_key_ids(@users, params)

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @users,
          Proc.new { |params| api_v1_users_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          {}
        )
      end
      format.csv do
        return_downloadable_csv(@users, 'users')
      end
    end
  end

  # POST /users
  include Swagger::Blocks
  swagger_path '/users' do
    operation :post do
      key :tags, ['admin']
      key :name, :tags
      key :summary, 'Create a user'
      key :description, 'Requires API authentication.'
      key :produces, ['application/json']
      # parameter do
      #   key :name, :applied
      #   key :in, :body
      #   key :description, 'Filter for feeds that have (or have not) been applied'
      #   key :required, false
      #   key :type, :boolean
      # end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :User
        end
      end
    end
  end
  def create
    @user = User.create!(user_params)
    return render json: @user
  end

  # DELETE /users/{id}
  include Swagger::Blocks
  swagger_path '/users/{id}' do
    operation :delete do
      key :tags, ['user']
      key :name, :tags
      key :summary, 'Delete a user'
      key :description, 'Requires API authentication.'
      key :produces, ['application/json']
      parameter do
        key :name, :id
        key :in, :url
        key :description, 'ID for user'
        key :required, true
        key :type, :integer
      end
      response 200 do
        # key :description, 'stop response'
        # schema do
        #   key :'$ref', :Changeset
        # end
      end
    end
  end
  def destroy
    @user.destroy!
    render json: {}, status: :no_content
  end

  # PUT /users/{id}
  include Swagger::Blocks
  swagger_path '/users/{id}' do
    operation :put do
      key :tags, ['admin']
      key :name, :tags
      key :summary, 'Edit a user'
      key :description, 'Requires API authentication.'
      key :produces, ['application/json']
      parameter do
        key :name, :id
        key :in, :url
        key :description, 'ID for user'
        key :required, true
        key :type, :integer
      end
      # TODO: body parameters
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :User
        end
      end
      security do
        key :api_auth_token, []
      end
    end
  end
  def update
    @user.update!(user_params)
    render json: @user
  end

  # GET /users/{id}
  include Swagger::Blocks
  swagger_path '/users/{id}' do
    operation :get do
      key :tags, ['user']
      key :name, :tags
      key :summary, 'Returns a single user'
      key :description, 'Requires API authentication.'
      key :produces, ['application/json']
      parameter do
        key :name, :id
        key :in, :url
        key :description, 'ID for user'
        key :required, true
        key :type, :integer
      end
      # TODO: body parameters
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :User
        end
      end
      security do
        key :api_auth_token, []
      end
    end
  end
  def show
    render json: @user
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :affiliation, :user_type)
  end

end
