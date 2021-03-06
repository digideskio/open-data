class DatasetsController < ApplicationController
  before_filter :find_dataset, :only => [:show, :edit, :update, :destroy, :count_download]
  before_filter :authenticate_admin!, :except => [:index, :show, :tagged_with, :in_category, :count_download]

  # GET /datasets
  # GET /datasets.xml
  def index
    @datasets = Dataset.find(:all, :order => 'is_featured desc, last_uploaded_at desc')

    respond_to do |wants|
      wants.html # index.html.erb
      wants.xml  { render :xml => @datasets }
    end
  end

  # GET /datasets/1
  # GET /datasets/1.xml
  def show
    @tags = @dataset.tags_on(:tags).map { |tag| tag.id }
    @apps = @dataset.apps.find(:all, :conditions => ['is_published = ?', true])
    respond_to do |wants|
      wants.html # show.html.erb
      wants.xml  { render :xml => @dataset }
    end
  end

  # GET /datasets/new
  # GET /datasets/new.xml
  def new
    @dataset = Dataset.new
    prep_dataset_form
    
    respond_to do |wants|
      wants.html # new.html.erb
      wants.xml  { render :xml => @dataset }
    end
  end

  # GET /datasets/1/edit
  def edit
    prep_dataset_form
  end

  # POST /datasets
  # POST /datasets.xml
  def create
    @dataset = Dataset.new(params[:dataset])
    prep_dataset_form
    @dataset.save!
    publish_press_item("New dataset added: #{@dataset.title}")

    respond_to do |wants|
      flash[:notice] = 'Dataset was successfully created.'
      wants.html { redirect_to(@dataset) }
      wants.xml  { render :xml => @dataset, :status => :created, :location => @dataset }
    end
  end

  # PUT /datasets/1
  # PUT /datasets/1.xml
  def update
    prep_dataset_form
    @dataset.update_attributes!(params[:dataset])
    publish_press_item("Dataset updated: #{@dataset.title}") if attachments_updated?
    
    respond_to do |wants|
      flash[:notice] = 'Dataset was successfully updated.'
      wants.html { redirect_to(@dataset) }
      wants.xml  { head :ok }
    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.xml
  def destroy
    @dataset.destroy

    respond_to do |wants|
      wants.html { redirect_to(datasets_url) }
      wants.xml  { head :ok }
    end
  end
  
  def tagged_with
    @tag = ActsAsTaggableOn::Tag.find_by_slug(params[:tag])
    @datasets = Dataset.tagged_with(@tag.name)

    respond_to do |wants|
      wants.html { render :action => :index }
      wants.xml  { render :xml => @datasets }
    end
  end
  
  def in_category
    @category = params[:category]
    raise ActiveRecord::RecordNotFound unless Configs.select_lists['dataset_categories'].values.keys.include?(@category)

    @datasets = Dataset.find(:all, :conditions => ['category = ?', @category])

    respond_to do |wants|
      wants.html { render :action => :index }
      wants.xml  { render :xml => @datasets }
    end
  end
  
  def count_download
    @dataset.download_count += 1
    @dataset.save!
    respond_to do |wants|
      wants.js { head :ok }
    end
  end

  protected
    def find_dataset
      @dataset = Dataset.find(params[:id])
    end
    
    def prep_dataset_form
      @max_files = Dataset::MAX_ATTACHMENTS

      tags = Dataset.tag_counts_on(:tags)
      @tags = tags.empty? ? Configs.dataset_tags : tags.map { |tag| {:value => tag.name} }
      @current_tags = @dataset.tag_list.map { |tag| {:value => tag} }

      standards = Dataset.tag_counts_on(:standards)
      @standards = standards.empty? ? Configs.dataset_standards : standards.map { |tag| {:value => tag.name} }
      @current_standards = @dataset.standard_list.map { |tag| {:value => tag} }

      certifications = Dataset.tag_counts_on(:certifications)
      @certifications = certifications.empty? ? Configs.dataset_certifications : certifications.map { |tag| {:value => tag.name} }
      @current_certifications = @dataset.certification_list.map { |tag| {:value => tag} }
    end
    
    def attachments_updated?
      params[:dataset][:attachments_attributes].each do |key,value|
        return true if value.has_key?('attachment')
      end
      false
    end

    # Publish news item for creation/updates
    def publish_press_item(press_title)
      press_item = PressItem.new
      press_item.title = press_title
      press_item.source = Configs.company_name
      press_item.link = dataset_url(@dataset)
      press_item.published_at = DateTime.now
      press_item.save!
    end
end
