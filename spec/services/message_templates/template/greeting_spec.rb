require 'rails_helper'

describe MessageTemplates::Template::Greeting do
  context 'when this hook is called' do
    let(:conversation) { create(:conversation) }

    it 'creates the email collect messages' do
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
    end

    it 'creates the greeting messages with template variable' do
      conversation.inbox.update!(greeting_message: 'Hey, {{contact.name}} welcome to our board.')
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.last.content).to eq("Hey, #{conversation.contact.name} welcome to our board.")
    end

    it 'creates the greeting messages with more than one variable strings' do
      conversation.inbox.update!(greeting_message: 'Hey, {{contact.name}} welcome to our board. - from {{account.name}}')
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.last.content).to eq("Hey, #{conversation.contact.name} welcome to our board. - from #{conversation.account.name}")
    end

    it 'creates the greeting messages' do
      conversation.inbox.update!(greeting_message: 'Hello welcome to our board.')
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.last.content).to eq('Hello welcome to our board.')
    end

    it 'marks greeting messages with template_type' do
      conversation.inbox.update!(greeting_message: 'Hello welcome to our board.')
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.last.content_attributes['template_type']).to eq('greeting')
    end
  end

  describe '.perform_if_applicable' do
    let(:conversation) { create(:conversation) }

    it 'creates a greeting when enabled and message is present' do
      conversation.inbox.update!(greeting_enabled: true, greeting_message: 'Hello welcome to our board.')

      expect do
        described_class.perform_if_applicable(conversation)
      end.to change { conversation.messages.template.count }.by(1)
      expect(conversation.messages.template.last.content_attributes['template_type']).to eq('greeting')
    end

    it 'does not create a greeting when greeting is disabled' do
      conversation.inbox.update!(greeting_enabled: false, greeting_message: 'Hello welcome to our board.')

      expect do
        described_class.perform_if_applicable(conversation)
      end.not_to(change { conversation.messages.template.count })
    end

    it 'does not create a greeting when a template message already exists' do
      conversation.inbox.update!(greeting_enabled: true, greeting_message: 'Hello welcome to our board.')
      create(:message, conversation: conversation, message_type: :template, content: 'existing')

      expect do
        described_class.perform_if_applicable(conversation)
      end.not_to(change { conversation.messages.template.count })
    end
  end
end
