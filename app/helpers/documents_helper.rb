module DocumentsHelper

  def format_field_content(field_name, content, document_id)
    temp_content = ""
    @search.hits.each do |hit|
      if (hit.instance.id.to_i == document_id)
        hit.highlights(field_name).each do |highlight|
          temp_content = temp_content + (highlight.format { |word| "<result class=\"highlight\">#{word}</result>" })
        end
      end
    end
    if (temp_content.blank? && (field_name == :temp_content))
      return temp_content
    end
    if (field_name == :content)
      temp_content =  format_content((temp_content.blank? ? content : temp_content), document_id)
    end
    temp_content.blank? ? content : temp_content
  end

  # Query documents
  def query_documents(is_edited)
    section_id = params[:section_id] unless params[:section_id].blank?
    @search_param = params[:search_param] unless params[:search_param].blank?
    @search_fields = ''
    @section = Section.find_by_id(section_id)
    section_ids = []
    section_ids = (@section.descendant_ids << @section.id) unless @section.blank?
    @search = Document.search do
      fulltext params[:search_param] do
          highlight :issuance_no, :fragment_size => 0
          highlight :title, :fragment_size => 0
          highlight :temp_content, :fragment_size => 150
          query_phrase_slop 0
          minimum_match 1
      end unless params[:search_param].blank?
      @issuance_no = params[:issuance_no] unless params[:issuance_no].blank?
      @title = params[:title] unless params[:title].blank?
      @signatory = params[:signatory] unless params[:signatory].blank?
      @content = params[:content] unless params[:content].blank?
      @date_from = params[:date_from].to_date unless params[:date_from].blank?
      @date_to = params[:date_to].to_date unless params[:date_to].blank?
      fulltext params[:signatory] do
          highlight :signatory, :fragment_size => 0
          fields :signatory => 10.0
          query_phrase_slop 0
      end unless params[:signatory].blank?

      fulltext params[:issuance_no] do
          highlight :issuance_no, :fragment_size => 0
          fields :issuance_no => 2.0
          query_phrase_slop 0
      end unless params[:issuance_no].blank?

      fulltext params[:title] do
          highlight :title, :fragment_size => 0
          fields :title => 10.0
          query_phrase_slop 0
      end unless params[:title].blank?

      fulltext params[:content] do
          highlight :temp_content, :fragment_size => 150
          fields :temp_content => 10.0
          query_phrase_slop 0
      end unless params[:content].blank?
      with(:is_edited, is_edited)
      with(:section_id, section_ids) unless section_id.blank?
      with(:doc_date, @date_from..@date_to) if (!@date_from.blank? && !@date_to.blank?)
      order_by :doc_date, :desc
      paginate :page => params[:page], :per_page => Constants::PAGE_COUNT
    end
    documents = @search.results
    documents
  end

  def user_has_documents(user_id)
    search =
      Document.search do
        with(:user_id, user_id)
      end
    return !search.results.empty?
  end

end
