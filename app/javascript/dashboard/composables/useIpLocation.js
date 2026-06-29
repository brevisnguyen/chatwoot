/**
 * Formats IP geolocation fields stored on contacts or user sessions.
 * Prefers stored names from MaxMind lookup over countries.js translations.
 */
export function formatIpLocation(source = {}) {
  const state = source.state || '';
  const city = source.city || '';
  const country = source.country || '';
  const countryCode = (
    source.country_code ||
    source.countryCode ||
    ''
  ).toUpperCase();

  const locationText = [state, city, country].filter(Boolean).join(', ');

  return {
    locationText,
    countryCode,
    hasLocation: Boolean(locationText),
  };
}

export function useIpLocation() {
  return { formatIpLocation };
}
