// Attachment URLs are generated with FRONTEND_URL as host. When agents open the
// dashboard on a different domain, serve attachments from the dashboard's own origin.
const ACTIVE_STORAGE_PATH = '/rails/active_storage/';

const { hostURL } = window.chatwootConfig || {};
const fromPrefix = hostURL
  ? `${new URL(hostURL).origin}${ACTIVE_STORAGE_PATH}`
  : '';
const toPrefix = `${window.location.origin}${ACTIVE_STORAGE_PATH}`;

const rewrite = value => {
  if (typeof value === 'string') {
    return value.startsWith(fromPrefix)
      ? toPrefix + value.slice(fromPrefix.length)
      : value;
  }
  if (Array.isArray(value)) return value.map(rewrite);
  if (value?.constructor === Object) {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, rewrite(item)])
    );
  }
  return value;
};

export const rewriteAttachmentHost = data => {
  if (!fromPrefix || fromPrefix === toPrefix) return data;
  return rewrite(data);
};
