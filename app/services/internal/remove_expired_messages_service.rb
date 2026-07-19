class Internal::RemoveExpiredMessagesService
  BATCH_SIZE = 1000
  PER_ACCOUNT_LIMIT = 50_000
  MINIMUM_RETENTION_MINUTES = 1440

  def perform
    total_deleted = 0

    Rails.logger.info '[RemoveExpiredMessagesService] Starting removal of expired messages'

    Account.with_message_retention.find_each(batch_size: 100) do |account|
      deleted = process_account(account)
      total_deleted += deleted
    end

    Rails.logger.info "[RemoveExpiredMessagesService] Completed. Total deleted: #{total_deleted}"
    total_deleted
  end

  private

  def process_account(account)
    retention = account.message_retention_after.to_i
    return 0 if retention < MINIMUM_RETENTION_MINUTES

    cutoff = retention.minutes.ago
    deleted_count = 0
    deleted_ids = []

    resolved_conversations_with_expired_messages(account, cutoff).find_each(batch_size: 100) do |conversation|
      break if deleted_count >= PER_ACCOUNT_LIMIT

      batch_ids = purge_conversation_messages(conversation, cutoff, PER_ACCOUNT_LIMIT - deleted_count)
      next if batch_ids.empty?

      deleted_count += batch_ids.size
      deleted_ids.concat(batch_ids)
      reconcile_last_activity!(conversation)
    end

    remove_from_search_index(deleted_ids)
    Rails.logger.info "[RemoveExpiredMessagesService] Account #{account.id}: deleted #{deleted_count} messages"
    deleted_count
  end

  def resolved_conversations_with_expired_messages(account, cutoff)
    expired_conversation_ids = account.messages.where('created_at < ?', cutoff).select(:conversation_id)
    account.conversations.resolved.where(id: expired_conversation_ids)
  end

  def purge_conversation_messages(conversation, cutoff, limit)
    deleted_ids = []

    expired_messages_scope(conversation, cutoff).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      batch.each do |message|
        break if deleted_ids.size >= limit

        message.destroy!
        deleted_ids << message.id
      end
      break if deleted_ids.size >= limit
    end

    deleted_ids
  end

  def expired_messages_scope(conversation, cutoff)
    scope = conversation.messages
                        .where('messages.created_at < ?', cutoff)
                        .where.not(content_type: :input_csat)
                        .left_joins(:csat_survey_response)
                        .where(csat_survey_responses: { id: nil })

    excluded_ids = excluded_message_ids_for(conversation)
    scope = scope.where.not(id: excluded_ids) if excluded_ids.present?
    scope
  end

  # Extension point for Enterprise (e.g. Captain::MessageReport exclusions)
  def excluded_message_ids_for(_conversation)
    []
  end

  def reconcile_last_activity!(conversation)
    last_at = conversation.messages.maximum(:created_at)
    conversation.update_columns(last_activity_at: last_at || conversation.created_at) # rubocop:disable Rails/SkipsModelValidations
  end

  def remove_from_search_index(message_ids)
    return unless ChatwootApp.advanced_search_allowed?
    return if message_ids.empty?

    records = message_ids.map { |id| Message.new(id: id) }
    Message.searchkick_index.bulk_delete(records)
  rescue StandardError => e
    Rails.logger.warn "[RemoveExpiredMessagesService] ES cleanup failed: #{e.message}"
  end
end

Internal::RemoveExpiredMessagesService.prepend_mod_with('Internal::RemoveExpiredMessagesService')
