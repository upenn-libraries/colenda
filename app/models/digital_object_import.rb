# frozen_string_literal: true

class DigitalObjectImport < ActiveRecord::Base
  QUEUED = 'queued'
  IN_PROGRESS = 'in_progress'
  FAILED = 'failed'
  SUCCESSFUL = 'successful'
  STATUSES = [QUEUED, IN_PROGRESS, FAILED, SUCCESSFUL].freeze

  belongs_to :bulk_import

  serialize :process_errors, Array
  serialize :import_data, JSON

  before_validation :set_default_status, on: :create

  validates :status, inclusion: { in: STATUSES }

  # status helpers
  STATUSES.each do |s|
    define_method "#{s}?" do
      status == s
    end
  end

  def process
    update(status: IN_PROGRESS)

    result = Bulwark::Import.new(created_by: bulk_import.created_by, **import_data.symbolize_keys).process

    update(
      status: result.status,
      process_errors: result.errors
    )
  end

  private

    def set_default_status
      self.status = QUEUED unless status
    end
end