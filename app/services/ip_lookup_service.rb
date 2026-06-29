class IpLookupService
  def perform(ip_address)
    return if ip_address.blank? || !ip_database_available?

    geocoder_result = Geocoder.search(ip_address).first
    return unless geocoder_result

    IpLookup::Result.new(
      city: geocoder_result.city,
      state: geocoder_result.state,
      country: geocoder_result.country,
      country_code: geocoder_result.country_code
    )
  rescue Errno::ETIMEDOUT => e
    Rails.logger.warn "Exception: IP resolution failed :#{e.message}"
  end

  private

  def ip_database_available?
    File.exist?(GeocoderConfiguration::LOOK_UP_DB)
  end
end
