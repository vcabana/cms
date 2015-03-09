class DocumentsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  before_filter :is_user_admin_or_editor?, :except => [:index, :show, :show_documents_side_by_side, :email_document]
  layout :false, :only => [:show, :edit, :show_documents_side_by_side]
  include DocumentsHelper

  def email_document
    @document = Document.find_by_id(params[:document_id])
    @shared_document = SharedDocument.new(params[:shared_document])
    ctr = 0
    if @shared_document.valid_attribute?(:shared_email_from)
      #first, we need to separate the emails with the semi colon
      email_addresses = params[:shared_document][:shared_email_to].split(";") unless params[:shared_document][:shared_email_to].blank?
      email_addresses.each do |email_address|
        #save the details in the ShareFolder table
          email_address = email_address.strip
          shared_document = SharedDocument.new(params[:shared_document])
          shared_document.document_id = @document.id
          shared_document.shared_email_to = email_address
          if shared_document.valid?
            ctr = ctr + 1
            shared_document.save
            #now send email to the recipients
            Delayed::Job.enqueue(EmailDocumentJob.new(shared_document))
          end
      end
    end
    redirect_to document_path(@document)

  end

  def show_documents_side_by_side
    @source_document = Document.find_by_id(params[:source_document_id])
    @cited_document = Document.find_by_id(params[:cited_document_id])
  end

  def index
    @documents = Document.all
  end

  def show
   @view_side_by_side_class_value = 'btn'
   @view_side_by_side_class_value = params[:view_side_by_side_class_value] unless params[:view_side_by_side_class_value].blank?

    @search = Document.search do
      fulltext params[:search_param] do
        highlight :content, :fragment_size => 0
        query_phrase_slop 0
        minimum_match 1
      end
      adjust_solr_params do |params|
        params['hl.maxAnalyzedChars'] = -1
        params['ht.maxAlternateFieldLength'] = -1
      end
      with(:id, params[:id])
    end
    @document = @search.results.first
    @document.content = format_document_content(@document)
    params[:attached_file] = AttachedFile.new
    params[:attached_file].document_id = @document.id unless @document.nil?
    params[:shared_document] = SharedDocument.new
    params[:shared_document].document_id = @document.id
  end

  def new
    @document = current_user.documents.new
    @section = Section.find_by_id(params[:section_id])
    @document.section_id = @section.id
  end

  def create
    @document = current_user.documents.new(params[:document])
    @document.is_edited = true
    if @document.save
      redirect_to browse_documents_path(@document.section), :notice => "Successfully created document."
    else
      flash[:error] = @document.errors.full_messages
      render :action => 'new'
    end
  end

  def edit
    @document = Document.find_by_id(params[:id])
    params[:attached_file] = AttachedFile.new
    params[:attached_file].document_id = @document.id unless @document.nil?
  end

  def update
    @document.is_edited = true
    if @document.update_attributes(params[:document])
      redirect_to @document, :notice  => "Successfully updated document."
    else
      flash[:error] = @document.errors.full_messages
      render :action => 'edit', :layout => false
    end
  end

  def destroy
    section = @document.section
    @document.delta = true
    if @document.destroy
      redirect_to browse_documents_path(section), :notice  => "Successfully deleted document."
    end
  end

end
