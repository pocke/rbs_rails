# frozen_string_literal: true

class Tag < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :project
end
