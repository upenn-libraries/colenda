# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigitalObjectImport, type: :model do
  let(:digital_object_import) { FactoryBot.build :digital_object_import }

  it 'has one BulkImport' do
    expect(digital_object_import.bulk_import).to be_a BulkImport
  end

  it 'has a status' do
    expect(digital_object_import.status).to be_a String
  end

  it 'can have an Array of process_errors' do
    expect(digital_object_import.process_errors).to be_a Array
  end

  it 'has an import_data hash' do
    expect(digital_object_import.import_data).to be_a String # JSON string
  end

  context 'validations' do
    context 'status' do
      xit 'allows nil' do; end
      xit 'allows only acceptable values' do; end
    end
  end
end
