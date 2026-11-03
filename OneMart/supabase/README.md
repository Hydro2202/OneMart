# OneMart — Supabase backend

## Applying the schema

**Dashboard (no CLI needed):** open your project → SQL Editor → paste the
full contents of `migrations/0001_init.sql` → Run.

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
