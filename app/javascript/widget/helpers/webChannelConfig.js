const KEY_LENGTH = 32;
const IV_LENGTH = 16;
const ENCRYPTED_FIELDS = ['websiteName', 'welcomeTagline', 'welcomeTitle'];
const MIN_ENCRYPTED_PAYLOAD_LENGTH = KEY_LENGTH + IV_LENGTH + 1;

const textDecoder = new TextDecoder();

const decodeBase64 = value => {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
};

const importAesKey = async keyBytes =>
  crypto.subtle.importKey('raw', keyBytes, { name: 'AES-CBC' }, false, [
    'decrypt',
  ]);

const isLikelyEncryptedPayload = value =>
  typeof value === 'string' &&
  value.length > MIN_ENCRYPTED_PAYLOAD_LENGTH &&
  /^[A-Za-z0-9+/=]+$/.test(value);

export const decryptField = async value => {
  if (value === null || value === undefined || value === '') {
    return value;
  }

  if (!isLikelyEncryptedPayload(value)) {
    return value;
  }

  try {
    const payload = decodeBase64(value);
    if (payload.length <= KEY_LENGTH + IV_LENGTH) {
      return value;
    }

    const key = payload.slice(0, KEY_LENGTH);
    const iv = payload.slice(KEY_LENGTH, KEY_LENGTH + IV_LENGTH);
    const ciphertext = payload.slice(KEY_LENGTH + IV_LENGTH);
    const cryptoKey = await importAesKey(key);
    const decrypted = await crypto.subtle.decrypt(
      { name: 'AES-CBC', iv },
      cryptoKey,
      ciphertext
    );

    return textDecoder.decode(decrypted);
  } catch {
    return value;
  }
};

export const decodeWebChannelTextFields = async () => {
  const channelConfig = window.chatwootWebChannel;
  if (!channelConfig || typeof channelConfig !== 'object') {
    return;
  }

  await Promise.all(
    ENCRYPTED_FIELDS.map(async field => {
      channelConfig[field] = await decryptField(channelConfig[field]);
    })
  );
};
