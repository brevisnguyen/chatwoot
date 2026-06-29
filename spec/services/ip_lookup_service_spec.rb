require 'rails_helper'

RSpec.describe IpLookupService do
  subject(:service) { described_class.new }

  let(:geocoder_result) do
    instance_double(
      'GeocoderResult',
      city: '深圳市',
      state: '广东省',
      country: '中国',
      country_code: 'CN'
    )
  end

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(GeocoderConfiguration::LOOK_UP_DB).and_return(true)
  end

  describe '#perform' do
    it 'returns an IpLookup::Result with localized geo fields' do
      allow(Geocoder).to receive(:search).with('1.1.1.1').and_return([geocoder_result])

      result = service.perform('1.1.1.1')

      expect(result).to eq(
        IpLookup::Result.new(
          city: '深圳市',
          state: '广东省',
          country: '中国',
          country_code: 'CN'
        )
      )
    end

    it 'returns nil when the IP address is blank' do
      expect(service.perform('')).to be_nil
    end

    it 'returns nil when the geo database is missing' do
      allow(File).to receive(:exist?).with(GeocoderConfiguration::LOOK_UP_DB).and_return(false)

      expect(service.perform('1.1.1.1')).to be_nil
    end

    it 'returns nil when geocoder finds no match' do
      allow(Geocoder).to receive(:search).with('1.1.1.1').and_return([])

      expect(service.perform('1.1.1.1')).to be_nil
    end

    it 'logs and returns nil on timeout' do
      allow(Geocoder).to receive(:search).and_raise(Errno::ETIMEDOUT.new('timeout'))
      allow(Rails.logger).to receive(:warn)

      expect(service.perform('1.1.1.1')).to be_nil
      expect(Rails.logger).to have_received(:warn).with(/IP resolution failed/)
    end
  end
end
