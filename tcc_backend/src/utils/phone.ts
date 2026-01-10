/**
 * Phone number utility functions for normalization and comparison
 */

/**
 * Normalize a phone number by removing common prefixes and formatting
 * - Removes leading zeros
 * - Removes spaces, dashes, parentheses
 * - Removes any '+' prefix
 */
export function normalizePhone(phone: string): string {
  if (!phone) return '';

  // Remove all non-digit characters
  let normalized = phone.replace(/\D/g, '');

  // Remove leading zeros
  normalized = normalized.replace(/^0+/, '');

  return normalized;
}

/**
 * Normalize a country code
 * - Removes '+' prefix
 * - Removes leading zeros
 */
export function normalizeCountryCode(countryCode: string): string {
  if (!countryCode) return '';

  // Remove all non-digit characters (including +)
  let normalized = countryCode.replace(/\D/g, '');

  // Remove leading zeros
  normalized = normalized.replace(/^0+/, '');

  return normalized;
}

/**
 * Compare two phone numbers for equality after normalization
 */
export function phoneEquals(phone1: string, phone2: string): boolean {
  return normalizePhone(phone1) === normalizePhone(phone2);
}

/**
 * Compare two country codes for equality after normalization
 */
export function countryCodeEquals(code1: string, code2: string): boolean {
  return normalizeCountryCode(code1) === normalizeCountryCode(code2);
}
