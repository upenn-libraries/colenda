module CustomEncodings
  module Marc21
    class Constants

      TAGS = {}

      TAGS['026'] = { 'e' => 'identifier'}
      TAGS['035'] = { 'a' => 'identifier'}
      TAGS['099'] = { 'a' => 'display_call_number'}
      TAGS['100'] = { '*' => 'creator' }
      TAGS['110'] = { '*' => 'author' }
      TAGS['245'] = { '*' => 'title' }
      TAGS['246'] = { 'a' => 'title' }
      TAGS['260'] = { 'b' => 'publisher' }
      TAGS['300'] = { '*' => 'format' }
      TAGS['590'] = { '*' => 'description' }
      TAGS['500'] = { '*' => 'bibliographic_note' }
      TAGS['510'] = { '*' => 'identifier' }
      TAGS['520'] = { '*' => 'abstract' }
      TAGS['524'] = { '*' => 'preferred_citation_note' }
      TAGS['530'] = { '*' => 'additional_physical_form_note' }
      TAGS['546'] = { '*' => 'language' }
      TAGS['561'] = { 'a' => 'provenance' }
      TAGS['581'] = { '*' => 'publications_note' }
      TAGS['600'] = { '*' => 'subject' }
      TAGS['650'] = { 'z' => 'coverage'
      }
      TAGS['651'] = { 'a' => 'coverage',
                      'y' => 'date',
                      'z' => 'coverage'
      }
      TAGS['655'] = { 'a' => 'subject',
                      'b' => 'subject',
                      'c' => 'subject',
                      'v' => 'subject',
                      'x' => 'subject',
                      'y' => 'subject',
                      'z' => 'subject',
                      '0' => 'subject',
                      '3' => 'subject',
                      '5' => 'subject',
                      '6' => 'subject',
                      '8' => 'subject'

      }
      TAGS['710'] = { 'a' => 'collection' }
      TAGS['730'] = { '*' => 'relation' }
      TAGS['740'] = { '*' => 'relation' }
      TAGS['856'] = { 'u' => 'relation' }

    end
  end
end

