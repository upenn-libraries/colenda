class Page < ActiveFedora::Base
  include Hydra::PCDM::ObjectBehavior
  contains "pageImage"
  property :page_id, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_searchable
    index.type :stored_searchable
  end

  property :file_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/fileName'), multiple: false do |index|
    index.as :stored_searchable
    index.type :stored_searchable
  end

  property :page_number, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/pageNumber'), multiple: false do |index|
    index.as :stored_searchable
    index.type :integer
  end

  property :ocr_text, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/pageText'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :item_type, predicate: ::RDF::Vocab::DC.type, multiple: false do |index|
    index.as :stored_searchable
  end

  property :parent_manuscript, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/parentManuscript'), multiple: false do |index|
    index.as :stored_searchable
  end

  belongs_to :manuscript, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

end
