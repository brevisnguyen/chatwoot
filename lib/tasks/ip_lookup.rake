require 'rubygems/package'

namespace :ip_lookup do
  task setup: :environment do
    Geocoder::SetupService.new.perform
  end

  desc 'Re-enqueue IP lookup for contacts with an IP but missing state'
  task refresh_contacts: :environment do
    Contact.find_each do |contact|
      ip = contact.additional_attributes&.dig('updated_at_ip') || contact.additional_attributes&.dig('created_at_ip')
      next if ip.blank?
      next if contact.additional_attributes&.dig('state').present?

      ContactIpLookupJob.perform_later(contact)
    end
  end

  desc 'Re-enqueue IP lookup for user sessions with an IP but missing geo data'
  task refresh_sessions: :environment do
    UserSession.where.not(ip_address: [nil, '']).where(state: nil).find_each do |session|
      UserSessionIpLookupJob.perform_later(session)
    end
  end
end
