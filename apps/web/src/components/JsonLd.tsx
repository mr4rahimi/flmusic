/**
 * تزریق JSON-LD. از <script type="application/ld+json"> استفاده می‌کنیم
 * چون گوگل همین را می‌خواند و در HTML سرور رندر می‌شود.
 */
export function JsonLd({ data }: { data: string }) {
  return (
    <script
      type="application/ld+json"
      // داده از سازنده‌های خودمان و JSON.stringify می‌آید، نه ورودی خام کاربر
      dangerouslySetInnerHTML={{ __html: data }}
    />
  );
}
