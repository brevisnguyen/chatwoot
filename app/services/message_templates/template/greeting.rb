class MessageTemplates::Template::Greeting
  pattr_initialize [:conversation!]

  def self.perform_if_applicable(conversation)
    return unless should_send?(conversation)

    new(conversation: conversation).perform
  end

  def self.should_send?(conversation)
    return false if conversation.campaign.present?
    return false if conversation.tweet?

    inbox = conversation.inbox
    first_message_from_contact?(conversation) && inbox.greeting_enabled? && inbox.greeting_message.present?
  end

  def self.first_message_from_contact?(conversation)
    conversation.messages.outgoing.count.zero? && conversation.messages.template.count.zero?
  end

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(greeting_message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  def greeting_message_params
    content = conversation.inbox&.greeting_message

    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: content,
      content_attributes: { template_type: 'greeting' }
    }
  end
end
MessageTemplates::Template::Greeting.singleton_class.prepend_mod_with('MessageTemplates::Template::Greeting')
