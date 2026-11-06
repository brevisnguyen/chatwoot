# housekeeping
# remove direct-uploaded blobs that never got attached to a record nor submitted in a form
# (e.g. a contact picked an image in a form field, then replaced it or left without submitting)

class Internal::RemoveAbandonedUploadsJob < ApplicationJob
  queue_as :housekeeping

  GRACE_PERIOD = 1.day

  def perform
    referenced_ids = form_image_blob_ids
    deleted = 0

    abandoned_blobs.find_each do |blob|
      next if referenced_ids.include?(blob.id)

      blob.purge
      deleted += 1
    end

    Rails.logger.info "[RemoveAbandonedUploadsJob] Purged #{deleted} abandoned uploads"
  end

  private

  # Blobs created via direct upload are only identified once attached, while server-side uploads
  # (editor images, inline email images) are identified on creation and referenced by URL instead.
  def abandoned_blobs
    ActiveStorage::Blob.left_joins(:attachments)
                       .where(active_storage_attachments: { id: nil })
                       .where('active_storage_blobs.created_at < ?', GRACE_PERIOD.ago)
                       .where('active_storage_blobs.metadata IS NULL OR active_storage_blobs.metadata NOT LIKE ?', '%"identified":true%')
  end

  def form_image_blob_ids
    Message.form.where("content_attributes::text LIKE '%submitted_values%'")
           .find_each.flat_map { |message| message.form_image_blobs.map(&:id) }.to_set
  end
end
