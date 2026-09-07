class Widget::BootstrapCipher
  KEY_LENGTH = 32
  IV_LENGTH = 16
  CIPHER_NAME = 'aes-256-cbc'

  class << self
    def encrypt(value)
      return value if value.nil? || value.blank?

      key = SecureRandom.random_bytes(KEY_LENGTH)
      iv = SecureRandom.random_bytes(IV_LENGTH)
      cipher = OpenSSL::Cipher.new(CIPHER_NAME)
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv
      ciphertext = cipher.update(value) + cipher.final

      Base64.strict_encode64(key + iv + ciphertext)
    end

    def decrypt(payload)
      return payload if payload.nil? || payload.blank?

      decoded = Base64.strict_decode64(payload)
      key = decoded[0, KEY_LENGTH]
      iv = decoded[KEY_LENGTH, IV_LENGTH]
      ciphertext = decoded[(KEY_LENGTH + IV_LENGTH)..]

      cipher = OpenSSL::Cipher.new(CIPHER_NAME)
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.update(ciphertext) + cipher.final
    end
  end
end
