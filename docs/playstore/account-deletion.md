<!--
Owner notes (delete before publishing):
- This is the public page Play asks for under App content → Data deletion ("Delete account URL").
  Host account-deletion.html and paste its URL in Play Console.
- Replace [OWNER_NAME], [CONTACT_EMAIL], [DELETION_FORM_URL], [BACKUP_DAYS].
- The in-app button only exists after a Dart change (see account-deletion-app.md) and after
  supabase/delete_account.sql has been run. Do not publish this page before both are live.
- Suggested Google Form fields: Google email used to sign in (required), name shown in the app,
  district, "I want my SmartLineman account and data deleted" (checkbox, required).
-->

# SmartLineman — অ্যাকাউন্ট মুছুন (Delete your account)

App: **SmartLineman** (`com.smartlineman.app`) · Developer: **[OWNER_NAME]**

[বাংলা](#বাংলা) · [English](#english)

---

## বাংলা

### অ্যাপ থেকে মোছার ধাপ

1. SmartLineman অ্যাপ খুলুন এবং Google দিয়ে লগইন থাকুন।
2. **সেটিংস** খুলুন (হোমের টুলবক্স → সেটিংস)।
3. পাতার নিচে **"অ্যাকাউন্ট মুছুন"** চাপুন।
4. সতর্কবার্তা পড়ে আবার **"হ্যাঁ, মুছুন"** চাপুন।
5. অ্যাকাউন্ট সঙ্গে সঙ্গে মুছে যাবে, অ্যাপ লগআউট হবে এবং এই ফোনে রাখা খেলার তথ্যও মুছে যাবে।

### অ্যাপ ছাড়া মোছার অনুরোধ

অ্যাপ না থাকলে বা খুলতে না পারলে:

- এই ফর্ম পূরণ করুন: **[DELETION_FORM_URL]**, অথবা
- যে Google ইমেল দিয়ে লগইন করেছিলেন, সেখান থেকে **[CONTACT_EMAIL]**-এ ইমেল করুন। বিষয়: **"Delete my SmartLineman account"**।

আপনার পরিচয় মিলিয়ে **30 দিনের মধ্যে** অ্যাকাউন্ট মুছে দেব এবং ইমেলে জানাব। অন্য কারো অ্যাকাউন্ট মোছা আটকাতে আমরা লগইনের ইমেল থেকেই অনুরোধ চাই।

### কী মুছে যায়

- প্রোফাইল: নাম, ইমেল, ফোন, জেলা, ব্লক, কাজ, SLM আইডি, ছবির লিংক, যাচাই স্থিতি
- পয়েন্ট, শেষ করা পাঠ ও লেভেল, কুইজের ফল
- লাইনম্যান লিগের সব ফল (মাসিক ও সর্বকালের) এবং মাসের সেরা ব্যাজ; বোর্ড আপনাকে বাদ দিয়ে নতুন করে হিসাব হয়
- লগইন অ্যাকাউন্ট (Google-এর সঙ্গে আমাদের সংযোগ)। একই অ্যাকাউন্ট smartlineman.in ওয়েবসাইটেও মুছে যায়।

### কী থাকে, এবং কতদিন

- লিগ বোর্ড প্রতিবার নতুন করে হিসাব হয়, তাই আপনার নাম বা পয়েন্ট কোথাও থাকে না। কোনো নামহীন পরিসংখ্যানও আলাদা করে রাখা হয় না।
- নিরাপত্তা ব্যাকআপে পুরোনো কপি সর্বোচ্চ **[BACKUP_DAYS] দিন** থাকে, তারপর নিজে থেকে মুছে যায়।
- সার্ভারের প্রযুক্তিগত লগ (যেমন IP ঠিকানা, সময়) পরিষেবা প্রদানকারীর নিয়মে অল্পদিন থাকে।
- আইনে রাখতে বাধ্য হলে শুধু সেটুকু রাখা হবে।

### অতিথি (Guest)

অতিথি হিসেবে খেললে কোনো অ্যাকাউন্ট নেই; সব তথ্য শুধু ফোনে। অ্যাপ আনইনস্টল করুন বা ফোনের সেটিংস → অ্যাপ → SmartLineman → স্টোরেজ → ডেটা মুছুন।

### অ্যাকাউন্ট না মুছে কিছু তথ্য মোছা

- ফোন নম্বর: সেটিংস → পরিচয় → ফোন ঘর খালি করুন।
- লিগে নাম: সেটিংস → লাইনম্যান লিগ → "বোর্ডে আমার নাম দেখান" বন্ধ করুন।
- অন্য কিছু: [CONTACT_EMAIL]-এ লিখুন।

---

## English

### Delete in the app

1. Open the SmartLineman app while signed in with Google.
2. Open **Settings** (Home toolbox → Settings).
3. At the bottom, tap **"Delete account"**.
4. Read the warning and tap **"Yes, delete"**.
5. Your account is deleted at once, the app signs you out, and the game data saved on this phone is cleared.

### Request deletion without the app

If you no longer have the app or cannot open it:

- Fill in this form: **[DELETION_FORM_URL]**, or
- Email **[CONTACT_EMAIL]** from the Google address you signed in with. Subject: **"Delete my SmartLineman account"**.

We check the request and delete the account **within 30 days**, then confirm by email. We ask for the request from your sign-in email so nobody can delete someone else's account.

### What is deleted

- Profile: name, email, phone, district, block, job, SLM ID, photo link, verification status
- Points, finished lessons and levels, quiz results
- All lineman league results (monthly and all-time) and monthly winner badges; the boards are recalculated without you
- The sign-in account (our link to your Google account). The same account is deleted on the smartlineman.in website too.

### What is kept, and for how long

- League boards are recalculated every time they are read, so your name and points do not remain anywhere. No separate anonymous statistics are kept either.
- Old copies in security backups last at most **[BACKUP_DAYS] days**, then expire automatically.
- Server technical logs (such as IP address and time) are kept briefly under our hosting providers' rules.
- Anything the law requires us to keep, and only that.

### Guests

Guest play has no account; all data is on the phone. Uninstall the app, or go to phone Settings → Apps → SmartLineman → Storage → Clear data.

### Delete some data without deleting the account

- Phone number: Settings → Profile → clear the Phone field.
- Name on the league: Settings → Lineman league → turn off "Show my name on the board".
- Anything else: write to [CONTACT_EMAIL].
