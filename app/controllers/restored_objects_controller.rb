require 'zip'

class RestoredObjectsController < ApplicationController
  before_action :set_restored_object, only: %i[show edit update destroy]

  layout :resolve_layout


  # GET /restored_objects
  # GET /restored_objects.json
  def index
    @objects = RestoredObject.all
  end

  # GET /restored_objects/1
  # GET /restored_objects/1.json
  def show
    #authorize @object
    #@pieces = @object.pieces
    gon.pieces = []
    gon.matrices = []
    gon.missings = []
    if  @object.object_type != nil
      gon.type = @object.object_type
    else
      gon.type = "ply"
    end
    @object.pieces.each do |p|
      gon.pieces << p.model.url
      gon.matrices << p.matrix
      gon.missings << p.missing
    end
  end

  # GET /restored_objects/new
  def new
    @object = RestoredObject.new
    @formats =  [ :ply, :obj, :stl, :other ]
    #authorize @object
  end

  # GET /restored_objects/1/edit
  def edit
    #authorize @object
  end

  # POST /restored_objects
  # POST /restored_objects.json
  def create
    @object = RestoredObject.new(restored_object_params)
    @object.user_id = current_user.id
    if params[:zip_file]
      params[:pieces_attributes] = nil
      puts "About to read the file"
      Zip::File.open(params[:zip_file].path) do |zipfile|
        puts "Reading zip file"
        zipfile.glob('*{ply,stl,obj}') do |file|
            puts "Reading #{file.name}"
            tempfile = Tempfile.new(File.basename(file.name))
            tempfile.binmode
            tempfile.write file.get_input_stream.read

            puts "Reading matrix"
            matrix = zipfile.glob("#{file.name.split('.').first}.txt").first.get_input_stream.read
            puts matrix

            @object.pieces.build(model: tempfile, model_file_name: file.name,
                                  name: file.name, matrix: matrix)

            tempfile.close
        end
      end
    end

    #authorize @object
    respond_to do |format|
      if @object.save
        format.html { redirect_to @object }
        format.json do
          render :show,
                 status: :created, location: @object
        end
      else
        puts @object.errors.first
        format.html { render :new }
        format.json do
          render json: @object.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /restored_objects/1
  # PATCH/PUT /restored_objects/1.json
  def update
    #authorize @object
    respond_to do |format|
      if @object.update(restored_object_params)
        format.html { redirect_to restored_object_path(@object) }
        format.json { render :show, status: :ok, location: @object }
      else
        format.html { render :edit }
        format.json do
          render json: @object.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /restored_objects/1
  # DELETE /restored_objects/1.json
  def destroy
    #authorize @object
    @object.destroy
    redirect_to(restored_objects_path)
  end

  private

  def resolve_layout
    case action_name
    when "show"
      "threejs"
    else
      "application"
    end
  end

  def set_restored_object
    @object = RestoredObject.find(params[:id])
  rescue StandardError
    redirect_to(restored_objects_path)
  end

  def restored_object_params
    params.require(:restored_object).permit(:title, :description, :notes,
      :classification, :author, :epoch, :avatar,
      :width, :height, :depth, :units_id, :state_id, :protection_id,
      :technique, :decoration, :owner, :deposit,
      :address, :longitude, :latitude, :in_inventory,
      :inventory_no, :priority_id, :zip_file, :object_type,
      pieces_attributes: [:id, :name, :description,
                          :model, :missing, :matrix, :restored_object_id, :_destroy],
      material_ids: [], category_ids: [], deterioration_ids: [])
  end
end
