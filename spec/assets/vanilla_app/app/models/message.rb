class Message < ActiveRecord::Base
  belongs_to :user

  def process
    "Message is being processed"
  end
end