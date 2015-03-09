class Document < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible :issuance_no, :title, :doc_date, :content, :user_id, :section_id, :is_edited, :signatory

  attr_accessor :temp_content, :section_ids

  # Association
  belongs_to :user
  has_many :attached_files, :dependent => :destroy
  belongs_to :section

  before_validation do
    self.content = self.content.gsub('&quot;', '"') unless self.content.blank?
    self.content = self.content.gsub("\"s", "'s") unless self.content.blank?
    self.issuance_no = self.issuance_no.strip.squeeze(" ") unless self.issuance_no.blank?
    self.title = self.title.strip.squeeze(" ") unless self.title.blank?
    self.signatory = self.signatory.strip.squeeze(" ") unless self.signatory.blank?
  end
  
#  before_save do
#    self.content = self.content.gsub('&quot;', '"') unless self.content.blank?
#    self.content = self.content.gsub('&quot;s', "'s") unless self.content.blank?
#  end

  # Validation
  validates :issuance_no, :title, :doc_date, :content, :section_id, :presence => true
  validates :issuance_no, :title, :uniqueness => true

  # Scope

  scope :by_title_or_issuance_no, lambda { |title_or_issuance_no|
    where('title like :title or issuance_no like :issuance_no',
        :title => "%#{title_or_issuance_no}%", :issuance_no => "%#{title_or_issuance_no}%")
  }

  scope :by_section_ids, lambda { |section_ids|
    where('section_id in (:section_ids)', :section_ids => section_ids)
  }

  # Sunspot index definition

  searchable do
    text :issuance_no, :stored => true
    text :title, :stored => true
    text :content, :stored => true
    text :temp_content, :stored => true do
      strip_tags(temp_content)
    end
    text :signatory, :stored => true
    time :doc_date
#    integer :section_ids, :multiple => true do
#      Section.all.map(&:id)
#    end
#    integer :section_ids, :references => Section, :multiple => true
#    integer :section_ids, :references => Section, :multiple => true
#    , :stored => true do
#      section_ids.all.map(&:section_id)
#    end
    integer :section_id, :references => Section, :multiple => true
#    integer :section_id
    boolean :is_edited
    integer :id
    integer :user_id

  end

#  def section_ids
#    section.documents.map(&:section_id)
#  end
  def document_date
    doc_date.to_s.tr('-', '').to_i unless doc_date.blank?
  end

  def temp_content
    self.temp_content = self.content
  end
end
