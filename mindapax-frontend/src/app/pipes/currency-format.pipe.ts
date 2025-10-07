import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'currencyFmt', standalone: true })
export class CurrencyFormatPipe implements PipeTransform {
  transform(amount: number | string | null | undefined, currency: string | null | undefined, locale?: string): string {
    const code = (currency || 'USD').toUpperCase();
    let value = 0;
    if (typeof amount === 'number') value = amount;
    else if (typeof amount === 'string') { const n = parseFloat(amount); value = isNaN(n) ? 0 : n; }
    const loc = code === 'XOF' ? 'fr-FR' : (locale || navigator.language || 'en-US');
    if (code === 'XOF') {
      // 0 decimals; show F CFA
      const s = new Intl.NumberFormat(loc, { style: 'currency', currency: 'XOF', minimumFractionDigits: 0, maximumFractionDigits: 0, currencyDisplay: 'code' }).format(value);
      // Replace code with custom symbol
      return s.replace('XOF', 'F\u00A0CFA');
    }
    try {
      return new Intl.NumberFormat(loc, { style: 'currency', currency: code }).format(value);
    } catch {
      return `${value.toFixed(2)} ${code}`;
    }
  }
}

