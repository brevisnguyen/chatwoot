module Enterprise::MessageTemplates::Template::Greeting
  def should_send?(conversation)
    return false if captain_handling_conversation?(conversation)

    super
  end

  private

  def captain_handling_conversation?(conversation)
    conversation.pending? &&
      conversation.inbox.respond_to?(:captain_assistant) &&
      conversation.inbox.captain_assistant.present?
  end
end
