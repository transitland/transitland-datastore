class Api::V1::ChangePayloadsController < Api::V1::BaseApiController
  include JsonCollectionPagination
  include AllowFiltering

  before_filter :require_api_auth_token, only: [:update, :create, :destroy]
  before_action :set_changeset, only: [:index, :create]
  before_action :set_change_payload, only: [:show, :update, :destroy]
  before_action :changeset_applied_lock, only: [:create, :update, :destroy]

  # GET changesets/{changeset_id}/change_payloads
  include Swagger::Blocks
  swagger_path '/changesets/{changeset_id}/change_payloads' do
    operation :get do
      key :tags, ['changeset']
      key :name, :tags
      key :summary, 'Returns all all change payloads included in a given changeset'
      key :produces, ['application/json']
      parameter do
        key :name, :changeset_id
        key :in, :path
        key :description, 'ID for changeset'
        key :required, true
        key :type, :integer
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :type, :array
          items do
            key :'$ref', :ChangePayload
          end
        end
      end
      security do
        key :api_auth_token, []
      end
    end
  end
  def index
    @change_payloads = @changeset.change_payloads

    @change_payloads = AllowFiltering.by_primary_key_ids(@change_payloads, params)

    respond_to do |format|
      format.json do
        render paginated_json_collection(
          @change_payloads,
          Proc.new { |params| api_v1_changeset_change_payloads_url(params) },
          params[:sort_key],
          params[:sort_order],
          params[:offset],
          params[:per_page],
          params[:total],
          params.slice()
        )
      end
    end
  end

  # POST changesets/{changeset_id}/change_payloads
  include Swagger::Blocks
  swagger_path '/changesets/{changeset_id}/change_payloads' do
    operation :post do
      key :tags, ['changeset']
      key :name, :tags
      key :summary, 'Append a change payload to the given changeset'
      key :produces, ['application/json']
      parameter do
        key :name, :changeset_id
        key :in, :path
        key :description, 'ID for changeset'
        key :required, true
        key :type, :integer
      end
      # TODO: param body
      response 200 do
        # key :description, 'stop response'
        schema do
          key :type, :array
          items do
            key :'$ref', :ChangePayload
          end
        end
      end
      security do
        key :api_auth_token, []
      end
    end
  end
  def create
    @change_payload = @changeset.change_payloads.create!(change_payload_params)
    render json: @change_payload
  end

  # GET changesets/{changeset_id}/change_payloads/{id}
  include Swagger::Blocks
  swagger_path '/changesets/{changeset_id}/change_payloads/{id}' do
    operation :get do
      key :tags, ['changeset']
      key :name, :tags
      key :summary, 'Returns one particular changeset in a given changeset'
      key :produces, ['application/json']
      parameter do
        key :name, :changeset_id
        key :in, :path
        key :description, 'ID for changeset'
        key :required, true
        key :type, :integer
      end
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID for change payload'
        key :required, true
        key :type, :integer
      end
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :ChangePayload
        end
      end
      security do
        key :api_auth_token, []
      end
    end
  end
  def show
    render json: @change_payload
  end

  # PUT changesets/{changeset_id}/change_payloads/{id}
  include Swagger::Blocks
  swagger_path '/changesets/{changeset_id}/change_payloads/{id}' do
    operation :put do
      key :tags, ['changeset']
      key :name, :tags
      key :summary, 'Update a particular changeset in a given changeset'
      key :produces, ['application/json']
      parameter do
        key :name, :changeset_id
        key :in, :path
        key :description, 'ID for changeset'
        key :required, true
        key :type, :integer
      end
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID for change payload'
        key :required, true
        key :type, :integer
      end
      # TODO: body params
      response 200 do
        # key :description, 'stop response'
        schema do
          key :'$ref', :ChangePayload
        end
      end
      security do
        key :api_auth_token, []
      end
    end
  end
  def update
    @change_payload.update!(change_payload_params)
    render json: @change_payload
  end

  # DELETE changesets/{changeset_id}/change_payloads/{id}
  include Swagger::Blocks
  swagger_path '/changesets/{changeset_id}/change_payloads/{id}' do
    operation :delete do
      key :tags, ['changeset']
      key :name, :tags
      key :summary, 'Delete a particular changeset from a given changeset'
      key :produces, ['application/json']
      parameter do
        key :name, :changeset_id
        key :in, :path
        key :description, 'ID for changeset'
        key :required, true
        key :type, :integer
      end
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID for change payload'
        key :required, true
        key :type, :integer
      end
      response 200 do
        # key :description, 'stop response'
        # schema do
        #   key :'$ref', :ChangePayload
        # end
      end
    end
  end
  def destroy
    @change_payload.destroy!
    render json: {}, status: :no_content
  end

  private

  def change_payload_params
    params.require(:change_payload).permit!
  end

  def changeset_applied_lock
    raise Changeset::Error.new(changeset: @changeset, message: 'cannot update a Changeset that has already been applied') if @changeset.applied
  end

  def set_changeset
    @changeset = Changeset.find(params[:changeset_id])
  end

  def set_change_payload
    @changeset = Changeset.find(params[:changeset_id])
    @change_payload = @changeset.change_payloads.find(params[:id])
  end
end
