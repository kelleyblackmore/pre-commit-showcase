/**
 * Convert an arbitrary string into a URL-safe slug.
 *
 * @param {string} input - The text to slugify.
 * @param {{ maxLength?: number }} [options] - Optional tuning.
 * @returns {string} A lowercase, hyphen-separated slug.
 */
export function slugify(input, options = {}) {
  const { maxLength = 80 } = options;

  if (typeof input !== 'string') {
    throw new TypeError(`slugify expects a string, received ${typeof input}`);
  }

  const slug = input
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

  if (slug.length <= maxLength) {
    return slug;
  }

  // Trim at a hyphen boundary so the slug never ends mid-word.
  const truncated = slug.slice(0, maxLength);
  const lastBoundary = truncated.lastIndexOf('-');
  return lastBoundary > 0 ? truncated.slice(0, lastBoundary) : truncated;
}
