import DOMPurify from 'dompurify';

const HTML_TAG_REGEX = /<\/?[a-z][\s\S]*>/i;

const GREETING_HTML_CONFIG = {
  ALLOWED_TAGS: [
    'p',
    'br',
    'strong',
    'b',
    'em',
    'i',
    'u',
    's',
    'a',
    'span',
    'div',
    'ul',
    'ol',
    'li',
  ],
  ALLOWED_ATTR: ['href', 'target', 'rel', 'style', 'class'],
  ALLOW_DATA_ATTR: false,
};

const ALLOWED_STYLE_PROPERTIES = new Set([
  'text-align',
  'color',
  'background-color',
]);

const sanitizeStyleValue = value => {
  return String(value || '')
    .replace(/url\s*\(/gi, '')
    .replace(/expression\s*\(/gi, '')
    .replace(/javascript:/gi, '');
};

const sanitizeStyleAttribute = styleValue => {
  if (!styleValue) return '';

  return styleValue
    .split(';')
    .map(declaration => declaration.trim())
    .filter(Boolean)
    .map(declaration => {
      const separatorIndex = declaration.indexOf(':');
      if (separatorIndex === -1) return null;

      const property = declaration
        .slice(0, separatorIndex)
        .trim()
        .toLowerCase();
      const value = sanitizeStyleValue(
        declaration.slice(separatorIndex + 1).trim()
      );
      if (!ALLOWED_STYLE_PROPERTIES.has(property) || !value) return null;

      return `${property}: ${value}`;
    })
    .filter(Boolean)
    .join('; ');
};

const sanitizeInlineStyles = html => {
  if (typeof document === 'undefined') {
    return html;
  }

  const doc = new DOMParser().parseFromString(html, 'text/html');
  doc.body.querySelectorAll('[style]').forEach(element => {
    const sanitizedStyle = sanitizeStyleAttribute(
      element.getAttribute('style')
    );
    if (sanitizedStyle) {
      element.setAttribute('style', sanitizedStyle);
    } else {
      element.removeAttribute('style');
    }
  });

  return doc.body.innerHTML;
};

export const isGreetingMessage = contentAttributes => {
  const attrs = contentAttributes || {};
  return (
    attrs.template_type === 'greeting' || attrs.templateType === 'greeting'
  );
};

export const looksLikeHtml = content => {
  if (!content || typeof content !== 'string') return false;
  return HTML_TAG_REGEX.test(content);
};

export const isGreetingHtml = (content, contentAttributes) => {
  return isGreetingMessage(contentAttributes) && looksLikeHtml(content);
};

export const sanitizeGreetingHtml = content => {
  if (!content) return '';

  const sanitized = DOMPurify.sanitize(content, GREETING_HTML_CONFIG);
  return sanitizeInlineStyles(sanitized);
};

export const formatGreetingContent = (
  content,
  contentAttributes,
  formatMessage
) => {
  if (isGreetingHtml(content, contentAttributes)) {
    return sanitizeGreetingHtml(content);
  }

  return formatMessage ? formatMessage(content, false) : content;
};
