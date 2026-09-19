# 🔗 کانفیگ‌های X4G — آماده‌ی ایمپورت در v2rayNG

| مورد | مقدار |
|---|---|
| 🌐 دامنه‌ی سرویس | `8000-irkhgea8tiww6evaw5sre.e2b.app` |
| 📊 داشبورد مدیریت | https://8000-irkhgea8tiww6evaw5sre.e2b.app/dashboard |
| 🔑 رمز پنل | `X4G!arena-2026` |
| 📡 پورت اتصال | `443` (TLS) |
| 🗂 تعداد کانفیگ | 3 |
| 📱 فایل QR آماده | `v2rayNG-QR.html` (یک صفحه، QR + دکمه‌ی کپی برای هر کانفیگ) |

## 📥 ایمپورت سریع در v2rayNG

1. اپ **v2rayNG** را باز کنید → منوی سه‌نقطه → **Import config from Clipboard** (بعد از کپی لینک زیر).
2. یا فایل `v2rayNG-QR.html` را باز کنید و با گزینه‌ی **Scan QR code** در v2rayNG، QR هر کانفیگ را اسکن کنید.
3. کانفیگ را انتخاب و دکمه‌ی اتصال را بزنید.

---

## 📋 خلاصه

| # | برچسب | ترابرد | fp | alpn | حجم | سرعت | آی‌پی | انقضا |
|---|---|---|---|---|---|---|---|---|
| 1 | `X4G-Main-WS` | vless-ws | `chrome` | `http/1.1` | نامحدود | نامحدود | نامحدود | بدون انقضا |
| 2 | `X4G-XHTTP` | xhttp (mode=auto) | `chrome` | `h2,http/1.1` | نامحدود | نامحدود | نامحدود | بدون انقضا |
| 3 | `X4G-5GB-30Days` | vless-ws | `firefox` | `http/1.1` | ۵ گیگابایت | ۲۰ Mbps | ۲ آی‌پی | ۳۰ روز |

---

## 1. X4G-Main-WS — کانفیگ اصلی — نامحدود

```
vless://a531f433-15ef-2660-a9e5-a2ba2c51ecc6@8000-irkhgea8tiww6evaw5sre.e2b.app:443?encryption=none&security=tls&type=ws&host=8000-irkhgea8tiww6evaw5sre.e2b.app&path=/ws/a531f433-15ef-2660-a9e5-a2ba2c51ecc6&sni=8000-irkhgea8tiww6evaw5sre.e2b.app&fp=chrome&alpn=http/1.1#X4G-X4G-Main-WS
```

- 🔗 لینک ساب: `https://8000-irkhgea8tiww6evaw5sre.e2b.app/sub/a531f433-15ef-2660-a9e5-a2ba2c51ecc6`
- 🖥️ صفحه‌ی عمومی: https://8000-irkhgea8tiww6evaw5sre.e2b.app/p/a531f433-15ef-2660-a9e5-a2ba2c51ecc6
- 🆔 UUID: `a531f433-15ef-2660-a9e5-a2ba2c51ecc6`

![QR X4G-Main-WS](qr/X4G-Main-WS.png)

## 2. X4G-XHTTP — کانفیگ XHTTP — نامحدود

```
vless://48a83ecd-0d8b-206d-488e-2a894cea4d6c@8000-irkhgea8tiww6evaw5sre.e2b.app:443?encryption=none&security=tls&type=xhttp&mode=auto&host=8000-irkhgea8tiww6evaw5sre.e2b.app&path=/xhttp-siz10/48a83ecd-0d8b-206d-488e-2a894cea4d6c&sni=8000-irkhgea8tiww6evaw5sre.e2b.app&fp=chrome&alpn=h2%2Chttp/1.1#X4G-X4G-XHTTP
```

- 🔗 لینک ساب: `https://8000-irkhgea8tiww6evaw5sre.e2b.app/sub/48a83ecd-0d8b-206d-488e-2a894cea4d6c`
- 🖥️ صفحه‌ی عمومی: https://8000-irkhgea8tiww6evaw5sre.e2b.app/p/48a83ecd-0d8b-206d-488e-2a894cea4d6c
- 🆔 UUID: `48a83ecd-0d8b-206d-488e-2a894cea4d6c`

![QR X4G-XHTTP](qr/X4G-XHTTP.png)

## 3. X4G-5GB-30Days — کانفیگ آزمایشی محدود

```
vless://1f720513-6f24-0d0f-0ebb-1fbbaa59d572@8000-irkhgea8tiww6evaw5sre.e2b.app:443?encryption=none&security=tls&type=ws&host=8000-irkhgea8tiww6evaw5sre.e2b.app&path=/ws/1f720513-6f24-0d0f-0ebb-1fbbaa59d572&sni=8000-irkhgea8tiww6evaw5sre.e2b.app&fp=firefox&alpn=http/1.1#X4G-X4G-5GB-30Days
```

- 🔗 لینک ساب: `https://8000-irkhgea8tiww6evaw5sre.e2b.app/sub/1f720513-6f24-0d0f-0ebb-1fbbaa59d572`
- 🖥️ صفحه‌ی عمومی: https://8000-irkhgea8tiww6evaw5sre.e2b.app/p/1f720513-6f24-0d0f-0ebb-1fbbaa59d572
- 🆔 UUID: `1f720513-6f24-0d0f-0ebb-1fbbaa59d572`

![QR X4G-5GB-30Days](qr/X4G-5GB-30Days.png)

---

## 🛠 اگر کانفیگ وصل نشد

- کانفیگ **XHTTP** را امتحان کنید (بعضی پراکسی‌های میانی WebSocket را عبور نمی‌دهند ولی HTTP/2 را عبور می‌دهند).
- در v2rayNG داخل تنظیمات همان کانفیگ: `fingerprint` را به `firefox` یا `randomized` و `alpn` را به `h2` تغییر دهید.
- اگر شبکه‌تان دسترسی به دامنه‌های `*.e2b.app` را فیلتر می‌کند، این دامنه برای شما بالا نمی‌آید — راه‌حل در بخش بعدی.

## 🚀 برای کانفیگ دائمی (دامنه‌ی خودتان)

این دامنه روی سشن موقت Arena اجرا شده و با بسته شدن سشن از کار می‌افتد. برای کانفیگ همیشگی:

1. ریپو را روی **Railway** دیپلوی کنید (همان روال README: Fork → New Project → Deploy from GitHub repo) و Volume روی `/data` وصل کنید.
2. یک Public Domain برای سرویس فعال کنید.
3. وارد `/dashboard` با رمز خودتان شوید و کانفیگ بسازید — **لینک‌ها به‌صورت خودکار با دامنه‌ی خودتان ساخته می‌شوند** (پنل دامنه را از هدر درخواست می‌خواند).

برای اجرای روی سرور خودتان هم کافی است:
```bash
PORT=8000 DATA_DIR=/data ADMIN_PASSWORD='یک-رمز-قوی' .venv/bin/python main.py
```
---

X4G · کانال یوتیوب: [@X4GHUB](https://www.youtube.com/@X4GHUB) · پشتیبانی: [گروه تلگرام](https://t.me/x4g_group)
