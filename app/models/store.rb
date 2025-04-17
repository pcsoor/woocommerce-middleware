class Store < ApplicationRecord
  belongs_to :user

  # encrypts :consumer_key
  # encrypts :consumer_secret

  validates :api_url, presence: true
end
