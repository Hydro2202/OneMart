# OneMart — Supabase backend

## Applying the schema

**Dashboard (no CLI needed):** open your project → SQL Editor → New query →
paste the full contents of `RUN_THIS_ONCE.sql` → Run. That file is just
`migrations/0001_init.sql` + `migrations/0002_wallet_guard.sql` combined
into one paste — if you change a migration, regenerate it (or run the
migrations one by one instead).

**Then run `RUN_THIS_SECOND.sql` the same way** (safe to re-run). It is
`migrations/0003_auto_confirm.sql` + `seed_demo_account.sql`:
- every new account is confirmed instantly, so sign-up logs straight in;
- creates the demo account **raiden@demo.com / password123** with ₱1,000 in
  its wallet (the Login screen's "Use demo account" button fills it in).
- sign-up goes through the `create_account` function (0004), which never
  sends an email — so "email rate limit exceeded" can no longer happen;
- re-running it repairs the demo account if it ever gets stuck.

**Email confirmation:** also turn off Authentication → Sign In / Providers →
Email → "Confirm email". The trigger above already makes login instant, but
with the setting on Supabase still tries to send a confirmation email, and
its free built-in mailer only allows a few per hour — after that, sign-up
fails with "email rate limit exceeded".

**CLI:**
```bash
supabase login
supabase link --project-ref YOUR-PROJECT-REF
supabase db push
```

## After running it

1. **Realtime** — the migration adds `chat_messages`, `message_threads`,
   `orders`, `parcel_timeline_events`, and `notifications` to the
   `supabase_realtime` publication directly. If your project already had a
   trimmed publication, double check Dashboard → Database → Replication
   shows these five toggled on.
2. **Storage** — three buckets are created (`avatars`, `catalog`, `listings`),
   all public-read. Seed `catalog` (restaurant/menu/product/merchant photos)
   from the Dashboard's Storage browser as an admin; `avatars` and `listings`
   are meant to be uploaded to by users themselves through the app, one
   folder per uploader (`<bucket>/<uid>/...`).
3. **Seed the catalog tables** — `merchants`, `restaurants`,
   `restaurant_categories`, `menu_sections`, `menu_items`, `products`,
   `ride_options`, `drivers` all start empty. The equivalent Swift mock data
   in `OneMart/MockData/` (MockRestaurants.swift, MockProducts.swift, etc.)
   is the reference for what to seed — same names, prices, and copy, just as
   rows instead of Swift literals.
4. **Never commit real credentials.** `OneMart/Supabase/SupabaseConfig.swift`
   (gitignored) holds your project's URL + anon key — see
   `SupabaseConfig.example.swift` next to it for the template.

## Design notes worth knowing before you extend this

- **Wallet balance is never client-writable.** It only ever changes through
  `pay_from_wallet()` / `top_up_wallet()`, two `SECURITY DEFINER` Postgres
  functions that lock the row, check the balance, and write the ledger row
  atomically. Don't add an app code path that does
  `update profiles set wallet_balance = ...` directly — that's the exact bug
  the original prototype had (silently clamping balance to 0), just moved
  server-side where it'd be worse.
- **The food cart's "one restaurant at a time" rule is enforced twice** — the
  confirmation dialog in `RestaurantDetailView` (Swift) and a
  `before insert or update` trigger on `cart_items` (SQL). Belt and
  suspenders: the trigger exists so a bug or a bypassed client can't silently
  violate the rule the UI promises.
- **`message_threads` has two unread counters** (`buyer_unread_count` /
  `seller_unread_count`), not one — "unread" only makes sense per participant
  once there are real, distinct users on both sides of a conversation. Read
  through `mark_thread_read(thread_id)`, never write the counters directly.
- **`public_profiles` is a view, not the `profiles` table.** Row Level
  Security can't hide individual columns, only rows — so anything that needs
  another user's name/photo (a listing card, a chat bubble) should query
  `public_profiles` (id, name, photo_path only), never `profiles` directly,
  which is locked to owner-only precisely so `wallet_balance`/`phone` never
  leak to other users.
