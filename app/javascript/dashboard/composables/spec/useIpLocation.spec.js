import { describe, expect, it } from 'vitest';
import { formatIpLocation } from '../useIpLocation';

describe('formatIpLocation', () => {
  it('formats state, city, and country in order', () => {
    expect(
      formatIpLocation({
        state: '广东省',
        city: '深圳市',
        country: '中国',
        country_code: 'CN',
      })
    ).toEqual({
      locationText: '广东省, 深圳市, 中国',
      countryCode: 'CN',
      hasLocation: true,
    });
  });

  it('supports camelCase countryCode', () => {
    expect(
      formatIpLocation({ city: 'Paris', countryCode: 'fr' }).countryCode
    ).toBe('FR');
  });

  it('returns empty values when no location fields are present', () => {
    expect(formatIpLocation({})).toEqual({
      locationText: '',
      countryCode: '',
      hasLocation: false,
    });
  });
});
