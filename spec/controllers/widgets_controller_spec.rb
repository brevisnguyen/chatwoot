require 'rails_helper'

describe '/widget', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) do
    create(
      :channel_widget,
      account: account,
      welcome_title: 'Secret Welcome Title',
      welcome_tagline: 'Secret welcome tagline'
    )
  end
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }

  before do
    web_widget.inbox.update!(name: 'Secret Inbox Name')
  end

  describe 'GET /widget' do
    it 'renders the page correctly when called with website_token' do
      get widget_url(website_token: web_widget.website_token)
      expect(response).to be_successful
      expect(response.body).not_to include(token)
      expect(response.body).not_to include('Secret Inbox Name')
      expect(response.body).not_to include('Secret Welcome Title')
      expect(response.body).not_to include('Secret welcome tagline')
      expect(response.body).to include(web_widget.website_token)
    end

    it 'renders the page correctly when called with website_token and cw_conversation' do
      get widget_url(website_token: web_widget.website_token, cw_conversation: token)
      expect(response).to be_successful
      expect(response.body).to include(token)
      expect(response.body).not_to include('Secret Inbox Name')
      expect(response.body).not_to include('Secret Welcome Title')
      expect(response.body).not_to include('Secret welcome tagline')
    end

    it 'returns 404 when called with out website_token' do
      get widget_url
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 if the account is suspended' do
      account.update!(status: :suspended)

      get widget_url(website_token: web_widget.website_token)
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('Account is suspended')
    end

    it 'returns 404 if the webwidget is deleted' do
      web_widget.delete

      get widget_url(website_token: web_widget.website_token)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('web widget does not exist')
    end
  end
end
