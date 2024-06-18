class ProjectGem < ApplicationRecord
  belongs_to :project

  validates :name, presence: true, allow_blank: false
  validates :org, presence: true, allow_blank: false
end