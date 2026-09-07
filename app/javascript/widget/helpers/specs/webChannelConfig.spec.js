import { createCipheriv, randomBytes } from 'crypto';
import {
  decryptField,
  decodeWebChannelTextFields,
} from '../webChannelConfig';

const encryptForTest = plainText => {
  const key = randomBytes(32);
  const iv = randomBytes(16);
  const cipher = createCipheriv('aes-256-cbc', key, iv);
  const encrypted = Buffer.concat([
    cipher.update(plainText, 'utf8'),
    cipher.final(),
  ]);

  return Buffer.concat([key, iv, encrypted]).toString('base64');
};

describe('webChannelConfig', () => {
  const originalChannelConfig = window.chatwootWebChannel;

  afterEach(() => {
    window.chatwootWebChannel = originalChannelConfig;
  });

  describe('#decryptField', () => {
    it('decrypts encrypted values', async () => {
      const encrypted = encryptForTest('Welcome to Acme');
      const decrypted = await decryptField(encrypted);

      expect(decrypted).toBe('Welcome to Acme');
    });

    it('returns plaintext values unchanged', async () => {
      await expect(decryptField('Acme Support')).resolves.toBe('Acme Support');
    });

    it('returns null and empty values unchanged', async () => {
      await expect(decryptField(null)).resolves.toBeNull();
      await expect(decryptField('')).resolves.toBe('');
    });
  });

  describe('#decodeWebChannelTextFields', () => {
    it('decodes encrypted fields on window.chatwootWebChannel', async () => {
      window.chatwootWebChannel = {
        websiteName: encryptForTest('Acme Support'),
        welcomeTagline: encryptForTest('We are here to help'),
        welcomeTitle: encryptForTest('Hello there'),
        websiteToken: 'token-123',
      };

      await decodeWebChannelTextFields();

      expect(window.chatwootWebChannel).toEqual({
        websiteName: 'Acme Support',
        welcomeTagline: 'We are here to help',
        welcomeTitle: 'Hello there',
        websiteToken: 'token-123',
      });
    });

    it('leaves plaintext test fixtures unchanged', async () => {
      window.chatwootWebChannel = {
        websiteName: 'Acme Support',
        welcomeTagline: 'We are here to help',
        welcomeTitle: 'Hello there',
      };

      await decodeWebChannelTextFields();

      expect(window.chatwootWebChannel.websiteName).toBe('Acme Support');
      expect(window.chatwootWebChannel.welcomeTagline).toBe(
        'We are here to help'
      );
      expect(window.chatwootWebChannel.welcomeTitle).toBe('Hello there');
    });
  });
});
