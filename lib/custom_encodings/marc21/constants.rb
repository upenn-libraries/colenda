module CustomEncodings
  module Marc21
    class Constants

      TAGS = {}

      TAGS['099'] = { 'a' => 'display_call_number'}
      TAGS['110'] = { '*' => 'author' }
      TAGS['245'] = { '*' => 'title' }
      TAGS['300'] = { '*' => 'description' }
      TAGS['500'] = { '*' => 'bibliographic_note' }
      TAGS['510'] = { '*' => 'citation_note' }
      TAGS['520'] = { '*' => 'abstract' }
      TAGS['524'] = { '*' => 'preferred_citation_note' }
      TAGS['530'] = { '*' => 'additional_physical_form_note' }
      TAGS['546'] = { '*' => 'language' }
      TAGS['561'] = { '*' => 'ownership_note' }
      TAGS['581'] = { '*' => 'publications_note' }
      TAGS['600'] = { '*' => 'subject' }
      TAGS['650'] = { 'a' => 'subject',
                      'z' => 'coverage'
      }
      TAGS['651'] = { 'a' => 'coverage',
                      'x' => 'subject',
                      'y' => 'date',
                      'z' => 'coverage'
      }
      TAGS['710'] = { 'a' => 'collection' }

    end
  end
end
