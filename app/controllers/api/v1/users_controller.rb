class Api::V1::UsersController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include DownloadableCsv
  include AllowFiltering

  before_filter :verify_jwt_token
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    @users = User.where('').includes{changesets}

    @users = AllowFiltering.by_primary_key_ids(@users, params)

    respond_to do |format|
      format.json { render paginated_json_collection(@users) }
      format.csv { return_downloadable_csv(@users, 'users') }
    end
  end

  def create
    @user = User.create!(user_params)
    return render json: @user
  end

  def destroy
    @user.destroy!
    render json: {}, status: :no_content
  end

  def update
    @user.update!(user_params)
    render json: @user
  end

  def show
    render json: @user
  end

  private

  def query_params
    super.merge({
      ids: {
        desc: "Users",
        type: "integer",
        array: true
      }
    })
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :affiliation, :user_type)
  end

end
