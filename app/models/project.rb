class Project < ApplicationRecord
  has_many :project_gems

  validates :name, presence: true, allow_blank: false
  validates :org, presence: true, allow_blank: false
end