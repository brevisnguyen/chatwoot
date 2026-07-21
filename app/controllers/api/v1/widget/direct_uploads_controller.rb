class Api::V1::Widget::DirectUploadsController < ActiveStorage::DirectUploadsController
  # Widget embeds are cross-origin (and often behind CDN/ESA), so session CSRF
  # cannot be verified. Auth is via website_token + X-Auth-Token instead.
  skip_before_action :verify_authenticity_token
  include WebsiteTokenHelper
  before_action :set_web_widget
  before_action :set_contact

  def create
    return if @contact.nil? || @current_account.nil?

    super
  end
end
