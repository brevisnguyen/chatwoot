# housekeeping
# remove expired messages from resolved conversations based on account retention settings

class Internal::RemoveExpiredMessagesJob < ApplicationJob
  queue_as :housekeeping

  def perform
    Internal::RemoveExpiredMessagesService.new.perform
  end
end
