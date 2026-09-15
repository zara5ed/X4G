# 🔗 کانفیگ‌های ساخته‌شده در X4G

سرور X4G اجرا شده و این کانفیگ‌ها داخل پنل ساخته شدند.

| مورد | مقدار |
|---|---|
| 🌐 دامنه سرویس | `8000-irkhgea8tiww6evaw5sre.e2b.app` |
| 📊 داشبورد مدیریت | https://8000-irkhgea8tiww6evaw5sre.e2b.app/dashboard |
| 🔑 رمز عبور پنل | `X4G!arena-2026` |
| 📡 پورت اتصال کانفیگ‌ها | `443` |
| 🛡️ امنیت | `TLS` (sni = دامنه سرویس) |
| 🗂 تعداد کانفیگ‌ها | 3 |

> ⚠️ این سرور داخل سندباکس موقت Arena اجرا شده؛ دامنه‌ی بالا فقط تا زمانی زنده است که این سشن فعال باشد. برای استفاده‌ی واقعی، همین ریپو را روی Railway (یا هر VPS/هاست دیگه) دیپلوی کنید و کانفیگ‌ها را با دامنه‌ی خودتان بسازید — کد و پنل کاملاً آماده است.

---

## 📋 خلاصه کانفیگ‌ها

| # | برچسب | ترابرد | Fingerprint | ALPN | حجم | سرعت | آی‌پی | انقضا |
|---|---|---|---|---|---|---|---|---|
| 1 | `X4G-Main-WS` | vless-ws (VLESS روی WebSocket) | `chrome` | `http/1.1` | نامحدود | نامحدود | نامحدود | بدون انقضا |
| 2 | `X4G-XHTTP` | xhttp (mode=auto → packet-up/stream-up) | `chrome` | `h2,http/1.1` | نامحدود | نامحدود | نامحدود | بدون انقضا |
| 3 | `X4G-5GB-30Days` | vless-ws (VLESS روی WebSocket) | `firefox` | `http/1.1` | ۵ گیگابایت | ۲۰ Mbps | ۲ آی‌پی | ۳۰ روز |

---

## 1. X4G-Main-WS — کانفیگ اصلی — نامحدود

**لینک VLESS (کپی کنید):**

```
vless://a531f433-15ef-2660-a9e5-a2ba2c51ecc6@8000-irkhgea8tiww6evaw5sre.e2b.app:443?encryption=none&security=tls&type=ws&host=8000-irkhgea8tiww6evaw5sre.e2b.app&path=/ws/a531f433-15ef-2660-a9e5-a2ba2c51ecc6&sni=8000-irkhgea8tiww6evaw5sre.e2b.app&fp=chrome&alpn=http/1.1#X4G-X4G-Main-WS
```

- 🔗 لینک ساب (متن base64): `https://8000-irkhgea8tiww6evaw5sre.e2b.app/sub/a531f433-15ef-2660-a9e5-a2ba2c51ecc6`
- 🖥️ صفحه‌ی عمومی کانفیگ: https://8000-irkhgea8tiww6evaw5sre.e2b.app/p/a531f433-15ef-2660-a9e5-a2ba2c51ecc6
- 🆔 UUID: `a531f433-15ef-2660-a9e5-a2ba2c51ecc6`

<img src="qr/X4G-Main-WS.png" alt="QR X4G-Main-WS" width="230">

## 2. X4G-XHTTP — کانفیگ XHTTP — نامحدود

**لینک VLESS (کپی کنید):**

```
vless://48a83ecd-0d8b-206d-488e-2a894cea4d6c@8000-irkhgea8tiww6evaw5sre.e2b.app:443?encryption=none&security=tls&type=xhttp&mode=auto&host=8000-irkhgea8tiww6evaw5sre.e2b.app&path=/xhttp-siz10/48a83ecd-0d8b-206d-488e-2a894cea4d6c&sni=8000-irkhgea8tiww6evaw5sre.e2b.app&fp=chrome&alpn=h2%2Chttp/1.1#X4G-X4G-XHTTP
```

- 🔗 لینک ساب (متن base64): `https://8000-irkhgea8tiww6evaw5sre.e2b.app/sub/48a83ecd-0d8b-206d-488e-2a894cea4d6c`
- 🖥️ صفحه‌ی عمومی کانفیگ: https://8000-irkhgea8tiww6evaw5sre.e2b.app/p/48a83ecd-0d8b-206d-488e-2a894cea4d6c
- 🆔 UUID: `48a83ecd-0d8b-206d-488e-2a894cea4d6c`

<img src="qr/X4G-XHTTP.png" alt="QR X4G-XHTTP" width="230">

## 3. X4G-5GB-30Days — کانفیگ آزمایشی محدود

**لینک VLESS (کپی کنید):**

```
vless://1f720513-6f24-0d0f-0ebb-1fbbaa59d572@8000-irkhgea8tiww6evaw5sre.e2b.app:443?encryption=none&security=tls&type=ws&host=8000-irkhgea8tiww6evaw5sre.e2b.app&path=/ws/1f720513-6f24-0d0f-0ebb-1fbbaa59d572&sni=8000-irkhgea8tiww6evaw5sre.e2b.app&fp=firefox&alpn=http/1.1#X4G-X4G-5GB-30Days
```

- 🔗 لینک ساب (متن base64): `https://8000-irkhgea8tiww6evaw5sre.e2b.app/sub/1f720513-6f24-0d0f-0ebb-1fbbaa59d572`
- 🖥️ صفحه‌ی عمومی کانفیگ: https://8000-irkhgea8tiww6evaw5sre.e2b.app/p/1f720513-6f24-0d0f-0ebb-1fbbaa59d572
- 🆔 UUID: `1f720513-6f24-0d0f-0ebb-1fbbaa59d572`

<img src="qr/X4G-5GB-30Days.png" alt="QR X4G-5GB-30Days" width="230">

---

## 📱 نحوه‌ی اتصال

1. اپ کلاینت را نصب کنید: **v2rayNG** (اندروید)، **Streisand / Shadowrocket** (iOS)، **NekoBox / v2rayN** (ویندوز و مک).
2. لینک VLESS بالا را کپی کنید و در کلاینت گزینه‌ی «Import from Clipboard» / «افزودن از کلیپ‌بورد» را بزنید — یا QR Code مربوطه را اسکن کنید.
3. یا لینک ساب را در بخش Subscription کلاینت وارد کنید تا خودکار آپدیت شود.

## ✅ تست‌هایی که انجام شد

- اجرای سرویس: `python main.py` روی پورت `8000` → `Application startup complete`
- `GET /health` → `{"status":"ok"}` و صفحه‌ی `/dashboard` بالا می‌آید
- تونل **VLESS-over-WebSocket** به‌صورت واقعی تست شد: کلاینت VLESS → WS → relay → TCP → پاسخ کامل HTTP برگشت ✅
- تونل **XHTTP (packet-up)** هم تست شد: آپلود هدر VLESS (`connected:true`) و دریافت داون‌لینک از مسیر `/xhttp-siz10/...` ✅
- لینک ساب `/sub/{uuid}`، صفحه‌ی عمومی `/p/{uuid}` و `GET /api/public/sub/{uuid}` هر سه پاسخ `200` دادند ✅

---

X4G · کانال یوتیوب: [@X4GHUB](https://www.youtube.com/@X4GHUB) · پشتیبانی: [گروه تلگرام](https://t.me/x4g_group)
