module Enterprise::Internal::RemoveExpiredMessagesService
  private

  def excluded_message_ids_for(conversation)
    super + Captain::MessageReport.where(conversation_id: conversation.id).pluck(:message_id)
  end
end
