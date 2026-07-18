import {
  formatGreetingContent,
  isGreetingHtml,
  isGreetingMessage,
  looksLikeHtml,
  sanitizeGreetingHtml,
} from '../greetingContentHelper';

describe('greetingContentHelper', () => {
  describe('isGreetingMessage', () => {
    it('detects snake_case template_type', () => {
      expect(isGreetingMessage({ template_type: 'greeting' })).toBe(true);
    });

    it('detects camelCase templateType', () => {
      expect(isGreetingMessage({ templateType: 'greeting' })).toBe(true);
    });

    it('returns false for other template types', () => {
      expect(isGreetingMessage({ template_type: 'out_of_office' })).toBe(false);
      expect(isGreetingMessage({})).toBe(false);
    });
  });

  describe('looksLikeHtml', () => {
    it('returns true for html strings', () => {
      expect(looksLikeHtml('<p style="text-align: center;">Hello</p>')).toBe(
        true
      );
    });

    it('returns false for plain markdown or text', () => {
      expect(looksLikeHtml('Hello **world**')).toBe(false);
      expect(looksLikeHtml('')).toBe(false);
    });
  });

  describe('isGreetingHtml', () => {
    it('requires greeting marker and html content', () => {
      expect(isGreetingHtml('<p>Hi</p>', { template_type: 'greeting' })).toBe(
        true
      );
      expect(
        isGreetingHtml('Hello **world**', { template_type: 'greeting' })
      ).toBe(false);
      expect(isGreetingHtml('<p>Hi</p>', {})).toBe(false);
    });
  });

  describe('sanitizeGreetingHtml', () => {
    it('keeps allowed text styles', () => {
      const html =
        '<p style="text-align: center; color: red; background-color: yellow;">Hello</p>';
      const sanitized = sanitizeGreetingHtml(html);

      expect(sanitized).toContain('text-align: center');
      expect(sanitized).toContain('color: red');
      expect(sanitized).toContain('background-color: yellow');
      expect(sanitized).toContain('Hello');
    });

    it('strips scripts and dangerous styles', () => {
      const html =
        '<p style="color: blue; background-image: url(https://evil.test)">Hi</p><script>alert(1)</script>';
      const sanitized = sanitizeGreetingHtml(html);

      expect(sanitized).not.toContain('<script>');
      expect(sanitized).not.toContain('background-image');
      expect(sanitized).toContain('color: blue');
      expect(sanitized).toContain('Hi');
    });
  });

  describe('formatGreetingContent', () => {
    it('returns sanitized html for greeting html content', () => {
      const result = formatGreetingContent(
        '<p style="text-align: center;">Welcome</p>',
        { template_type: 'greeting' },
        () => 'should-not-use-markdown'
      );

      expect(result).toContain('text-align: center');
      expect(result).toContain('Welcome');
      expect(result).not.toBe('should-not-use-markdown');
    });

    it('falls back to markdown formatter for legacy greeting text', () => {
      const formatMessage = vi.fn(() => '<p>formatted</p>');
      const result = formatGreetingContent(
        'Hello **world**',
        { template_type: 'greeting' },
        formatMessage
      );

      expect(formatMessage).toHaveBeenCalledWith('Hello **world**', false);
      expect(result).toBe('<p>formatted</p>');
    });
  });
});
