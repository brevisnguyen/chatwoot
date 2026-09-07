require 'rails_helper'

describe Widget::BootstrapCipher do
  describe '.encrypt' do
    it 'returns nil for nil values' do
      expect(described_class.encrypt(nil)).to be_nil
    end

    it 'returns blank values without encrypting' do
      expect(described_class.encrypt('')).to eq('')
    end

    it 'encrypts and decrypts a value' do
      encrypted = described_class.encrypt('Acme Support')
      decrypted = described_class.decrypt(encrypted)

      expect(encrypted).not_to eq('Acme Support')
      expect(decrypted).to eq('Acme Support')
    end
  end

  describe '.decrypt' do
    it 'returns nil for nil values' do
      expect(described_class.decrypt(nil)).to be_nil
    end

    it 'returns blank values without decrypting' do
      expect(described_class.decrypt('')).to eq('')
    end
  end
end
