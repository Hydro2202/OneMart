-- ============================================================================
-- OneMart — FULL DATABASE SETUP (run ONCE on a brand-new Supabase project)
--
-- Supabase Dashboard → SQL Editor → New query → paste this whole file → Run.
-- This is simply migrations/0001_init.sql followed by
-- migrations/0002_wallet_guard.sql, combined so it's one paste.
-- Running it a second time will error ("already exists") — that's expected
-- and harmless; it means the setup is already done.
-- ============================================================================

-- OneMart — initial schema
--
-- Run this in Supabase Dashboard → SQL Editor (or `supabase db push` if
-- you're using the CLI with this repo's `supabase/` folder). Safe to run
-- once against a fresh project; re-running will error on the `create table`
-- statements since nothing here is wrapped in `if not exists` guards on
-- purpose — that's a deliberate nudge to review before re-running against a
-- project that already has data.
--
-- Conventions used throughout:
--   * text columns that mirror a Swift `String`-backed enum store the exact
--     `rawValue` string (e.g. status = 'On the Way', not 'on_the_way'), so
--     `SomeEnum(rawValue:)` round-trips with zero translation layer.
--   * every table has RLS enabled; policies scope rows to `auth.uid()`.
--   * money is `numeric(12,2)`; timestamps are `timestamptz`.


-- ============================================================================
-- PROFILES  (extends auth.users — one row per signed-up user)
-- ============================================================================

create table public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  name           text not null,
  phone          text not null default '',
  photo_path     text,                          -- storage object path in the `avatars` bucket, not a public URL
  member_since   timestamptz not null default now(),
  wallet_balance numeric(12,2) not null default 0 check (wallet_balance >= 0),
  created_at     timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are viewable by their owner"
  on public.profiles for select
  using (auth.uid() = id);
  -- Deliberately owner-only, not "any authenticated user": Postgres RLS
  -- policies for the same command are OR'd together, and RLS can't restrict
  -- individual columns — a second, broader SELECT policy here would leak
  -- every column (wallet_balance included) to any other signed-in user. Use
  -- `public_profiles` below wherever the UI needs another user's name/photo
  -- (marketplace listings, chat).

create policy "users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);
  -- Note: wallet_balance is NOT meant to be client-writable even though this
  -- policy technically allows it — enforce that in the app layer by only ever
  -- calling pay_from_wallet()/top_up_wallet() below, never `update profiles
  -- set wallet_balance = ...` directly. (A stricter version of this policy
  -- using a `before update` trigger that rejects wallet_balance changes from
  -- non-SECURITY DEFINER contexts is a good hardening step before shipping.)

-- Auto-create a profile row the moment someone signs up.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'phone', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Safe, narrow read of *other* users — what a listing card, a seller row, or
-- a chat bubble is allowed to show. Owned by the migration role, which owns
-- `profiles` and is therefore exempt from its RLS policies, so this view
-- intentionally sees every row while only ever exposing three columns —
-- never wallet_balance, phone, or anything else private.
create view public.public_profiles as
select id, name, photo_path
from public.profiles;

grant select on public.public_profiles to authenticated;


-- ============================================================================
-- SAVED ADDRESSES
-- ============================================================================

create table public.saved_addresses (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  label        text not null,
  full_address text not null,
  icon         text not null default 'mappin.circle.fill',
  is_default   boolean not null default false,
  created_at   timestamptz not null default now()
);

alter table public.saved_addresses enable row level security;

create policy "users manage their own addresses"
  on public.saved_addresses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Only one default address per user.
create unique index one_default_address_per_user
  on public.saved_addresses (user_id)
  where is_default;


-- ============================================================================
-- WALLET  (transactions ledger + safe mutation RPCs)
-- ============================================================================

create table public.wallet_transactions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  module         text check (module in ('food', 'rides', 'logistics', 'shop', 'community')),  -- null = wallet-level event (top-up)
  type           text not null check (type in ('Payment', 'Top Up', 'Refund', 'Cashback')),
  title          text not null,
  subtitle       text not null default '',
  amount         numeric(12,2) not null check (amount > 0),
  payment_method text not null check (payment_method in ('OneMart Wallet', 'GCash', 'Credit / Debit Card', 'Cash on Delivery')),
  created_at     timestamptz not null default now()
);

alter table public.wallet_transactions enable row level security;

create policy "users read their own wallet transactions"
  on public.wallet_transactions for select
  using (auth.uid() = user_id);

-- No insert/update/delete policy for wallet_transactions: rows are only ever
-- written by the SECURITY DEFINER functions below, never directly by the
-- client, so a compromised/buggy client can't fabricate a payment or refund.

create function public.pay_from_wallet(
  p_amount numeric,
  p_title text,
  p_subtitle text default '',
  p_module text default null
)
returns boolean
language plpgsql
security definer set search_path = public
as $$
declare
  v_balance numeric(12,2);
begin
  if p_amount <= 0 then
    return false;
  end if;

  select wallet_balance into v_balance
  from public.profiles
  where id = auth.uid()
  for update;  -- lock the row so two concurrent payments can't both pass the balance check

  if v_balance is null or v_balance < p_amount then
    return false;  -- insufficient funds — balance is left untouched, matching the app's
                    -- "never silently clamp to 0" rule from the client-side fix
  end if;

  update public.profiles
  set wallet_balance = wallet_balance - p_amount
  where id = auth.uid();

  insert into public.wallet_transactions (user_id, module, type, title, subtitle, amount, payment_method)
  values (auth.uid(), p_module, 'Payment', p_title, p_subtitle, p_amount, 'OneMart Wallet');

  return true;
end;
$$;

create function public.top_up_wallet(
  p_amount numeric,
  p_payment_method text,
  p_method_label text
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if p_amount <= 0 then
    raise exception 'Top-up amount must be positive';
  end if;

  update public.profiles
  set wallet_balance = wallet_balance + p_amount
  where id = auth.uid();

  insert into public.wallet_transactions (user_id, module, type, title, subtitle, amount, payment_method)
  values (auth.uid(), null, 'Top Up', 'Wallet Top-Up', 'via ' || p_method_label, p_amount, p_payment_method);
end;
$$;

grant execute on function public.pay_from_wallet to authenticated;
grant execute on function public.top_up_wallet to authenticated;


-- ============================================================================
-- CATALOG — merchants, restaurants, menus, products
-- (public read for everyone signed in; no user-generated writes — manage
-- from the Supabase dashboard/Table Editor, or a future admin tool)
-- ============================================================================

create table public.merchants (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  logo_path         text,                        -- storage object path, or an SF Symbol name as a placeholder fallback
  is_official_store boolean not null default false,
  rating            numeric(2,1) not null default 5.0 check (rating between 0 and 5),
  response_rate     int not null default 100 check (response_rate between 0 and 100)
);

create table public.restaurants (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  image_path       text,                          -- storage object path — see "Real photo swap point" comments in the app
  neighborhood     text not null,
  rating           numeric(2,1) not null default 5.0 check (rating between 0 and 5),
  rating_count     int not null default 0,
  eta_min_minutes  int not null,
  eta_max_minutes  int not null,
  delivery_fee     numeric(10,2) not null default 0,
  is_promoted      boolean not null default false,
  price_level      int not null default 2 check (price_level between 1 and 3),
  distance_km      numeric(6,2) not null default 0,
  is_grocery_store boolean not null default false,
  tagline          text not null default ''
);

create table public.restaurant_categories (
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  category      text not null check (category in (
    'Filipino', 'Fast Food', 'Coffee & Tea', 'Desserts', 'Grocery', 'Healthy', 'Korean & Japanese', 'Street Food'
  )),
  primary key (restaurant_id, category)
);

create table public.menu_sections (
  id            uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  title         text not null,
  sort_order    int not null default 0
);

create table public.menu_items (
  id              uuid primary key default gen_random_uuid(),
  section_id      uuid not null references public.menu_sections (id) on delete cascade,
  name            text not null,
  description     text not null default '',
  image_path      text,
  price           numeric(10,2) not null check (price >= 0),
  is_best_seller  boolean not null default false,
  is_spicy        boolean not null default false,
  calories        int,
  sort_order      int not null default 0
);

create table public.products (
  id                  uuid primary key default gen_random_uuid(),
  name                text not null,
  image_path          text,
  merchant_id         uuid not null references public.merchants (id) on delete cascade,
  price               numeric(10,2) not null check (price >= 0),
  original_price      numeric(10,2),
  units_sold          int not null default 0,
  rating              numeric(2,1) not null default 5.0 check (rating between 0 and 5),
  is_flash_deal       boolean not null default false,
  flash_deal_ends_at  timestamptz,
  stock_remaining     int,
  is_escrow_protected boolean not null default true,
  category            text not null check (category in (
    'Electronics', 'Fashion', 'Home & Living', 'Beauty', 'Groceries', 'Accessories'
  ))
);

alter table public.merchants enable row level security;
alter table public.restaurants enable row level security;
alter table public.restaurant_categories enable row level security;
alter table public.menu_sections enable row level security;
alter table public.menu_items enable row level security;
alter table public.products enable row level security;

create policy "catalog is readable by signed-in users" on public.merchants for select using (auth.role() = 'authenticated');
create policy "catalog is readable by signed-in users" on public.restaurants for select using (auth.role() = 'authenticated');
create policy "catalog is readable by signed-in users" on public.restaurant_categories for select using (auth.role() = 'authenticated');
create policy "catalog is readable by signed-in users" on public.menu_sections for select using (auth.role() = 'authenticated');
create policy "catalog is readable by signed-in users" on public.menu_items for select using (auth.role() = 'authenticated');
create policy "catalog is readable by signed-in users" on public.products for select using (auth.role() = 'authenticated');

-- No insert/update/delete policies on catalog tables: writes go through the
-- Table Editor (as an admin) or the service_role key from a trusted backend,
-- never from the app. Add seller-managed products/restaurants as a later
-- phase with its own ownership + policy design.


-- ============================================================================
-- MARKETPLACE — community listings, favorites, messaging
-- ============================================================================

create table public.marketplace_listings (
  id                   uuid primary key default gen_random_uuid(),
  seller_id            uuid not null references public.profiles (id) on delete cascade,
  title                text not null,
  image_path           text,
  price                numeric(10,2) not null default 0,
  is_free              boolean not null default false,
  condition            text not null check (condition in ('Brand New', 'Like New', 'Good', 'Fair')),
  category             text not null check (category in ('Electronics', 'Furniture', 'Vehicles', 'Fashion', 'Hobbies', 'Free Stuff')),
  location_name        text not null,
  distance_km          numeric(6,2) not null default 0,
  description          text not null default '',
  is_delivery_available boolean not null default true,
  posted_at            timestamptz not null default now()
);

alter table public.marketplace_listings enable row level security;

create policy "listings are readable by signed-in users"
  on public.marketplace_listings for select
  using (auth.role() = 'authenticated');

create policy "sellers manage their own listings"
  on public.marketplace_listings for insert
  with check (auth.uid() = seller_id);

create policy "sellers update/delete their own listings"
  on public.marketplace_listings for update using (auth.uid() = seller_id) with check (auth.uid() = seller_id);

create policy "sellers delete their own listings"
  on public.marketplace_listings for delete using (auth.uid() = seller_id);

create table public.favorites (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  entity_type text not null check (entity_type in ('restaurant', 'product', 'listing')),
  entity_id   uuid not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, entity_type, entity_id)
);

alter table public.favorites enable row level security;

create policy "users manage their own favorites"
  on public.favorites for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table public.message_threads (
  id                  uuid primary key default gen_random_uuid(),
  listing_id          uuid references public.marketplace_listings (id) on delete set null,
  buyer_id            uuid not null references public.profiles (id) on delete cascade,
  seller_id           uuid not null references public.profiles (id) on delete cascade,
  -- Two counters, not one: "unread" is relative to whichever side is asking,
  -- unlike the original prototype's single `unreadCount` (which only had to
  -- make sense for one mock user). Kept in sync by a trigger on
  -- chat_messages below, never written to directly by the client.
  buyer_unread_count  int not null default 0,
  seller_unread_count int not null default 0,
  last_activity       timestamptz not null default now()
);

create table public.chat_messages (
  id         uuid primary key default gen_random_uuid(),
  thread_id  uuid not null references public.message_threads (id) on delete cascade,
  sender_id  uuid not null references public.profiles (id) on delete cascade,
  text       text not null,
  sent_at    timestamptz not null default now()
);

alter table public.message_threads enable row level security;
alter table public.chat_messages enable row level security;

create policy "participants read their own threads"
  on public.message_threads for select
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

create policy "buyers start threads"
  on public.message_threads for insert
  with check (auth.uid() = buyer_id);

create policy "participants read messages in their threads"
  on public.chat_messages for select
  using (
    exists (
      select 1 from public.message_threads t
      where t.id = thread_id and (t.buyer_id = auth.uid() or t.seller_id = auth.uid())
    )
  );

create policy "participants send messages in their threads"
  on public.chat_messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.message_threads t
      where t.id = thread_id and (t.buyer_id = auth.uid() or t.seller_id = auth.uid())
    )
  );

-- Bumps last_activity and increments the *recipient's* unread counter —
-- keeps message_threads in sync so the client never writes those columns
-- itself (no RLS update policy is granted on message_threads at all).
create function public.handle_new_chat_message()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  update public.message_threads
  set last_activity = new.sent_at,
      buyer_unread_count = case when new.sender_id = seller_id then buyer_unread_count + 1 else buyer_unread_count end,
      seller_unread_count = case when new.sender_id = buyer_id then seller_unread_count + 1 else seller_unread_count end
  where id = new.thread_id;
  return new;
end;
$$;

create trigger on_chat_message_inserted
  after insert on public.chat_messages
  for each row execute procedure public.handle_new_chat_message();

-- Zeroes out whichever side's counter belongs to the caller.
create function public.mark_thread_read(p_thread_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.message_threads
  set buyer_unread_count = case when buyer_id = auth.uid() then 0 else buyer_unread_count end,
      seller_unread_count = case when seller_id = auth.uid() then 0 else seller_unread_count end
  where id = p_thread_id
    and (buyer_id = auth.uid() or seller_id = auth.uid());
end;
$$;

grant execute on function public.mark_thread_read to authenticated;

-- Realtime: enable so MessagesView/MessageThreadView can subscribe instead of
-- polling. (Dashboard → Database → Replication → toggle these on, or:)
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.message_threads;


-- ============================================================================
-- ORDERS  (Food, Rides, Send, Shop, Community checkouts all land here)
-- ============================================================================

create table public.orders (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  module     text not null check (module in ('food', 'rides', 'logistics', 'shop', 'community')),
  title      text not null,
  subtitle   text not null default '',
  image_name text not null,                        -- an SF Symbol name (status/category glyph, not a photo)
  status     text not null check (status in ('Placed', 'Preparing', 'On the Way', 'Completed', 'Cancelled')),
  total      numeric(12,2) not null check (total >= 0),
  placed_at  timestamptz not null default now()
);

alter table public.orders enable row level security;

create policy "users manage their own orders"
  on public.orders for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter publication supabase_realtime add table public.orders;


-- ============================================================================
-- LOGISTICS  (parcels + tracking timeline)
-- ============================================================================

create table public.parcels (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles (id) on delete cascade,
  order_id           uuid references public.orders (id) on delete set null,
  tracking_code      text not null unique,
  pickup_address     jsonb not null,   -- {label, fullAddress, contactName, contactPhone} snapshot at booking time
  dropoff_address    jsonb not null,
  size               text not null check (size in ('Small', 'Medium', 'Large', 'Bulky / Freight')),
  is_bulky_freight   boolean not null default false,
  weight_kg          numeric(6,2) not null check (weight_kg > 0),
  item_description   text not null,
  fare               numeric(10,2) not null check (fare >= 0),
  status             text not null check (status in ('Picked Up', 'In Transit', 'Out for Delivery', 'Delivered')),
  requested_at       timestamptz not null default now()
);

create table public.parcel_timeline_events (
  id           uuid primary key default gen_random_uuid(),
  parcel_id    uuid not null references public.parcels (id) on delete cascade,
  status       text not null check (status in ('Picked Up', 'In Transit', 'Out for Delivery', 'Delivered')),
  note         text not null default '',
  is_completed boolean not null default false,
  event_at     timestamptz not null default now()
);

alter table public.parcels enable row level security;
alter table public.parcel_timeline_events enable row level security;

create policy "users manage their own parcels"
  on public.parcels for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users read timeline events for their own parcels"
  on public.parcel_timeline_events for select
  using (exists (select 1 from public.parcels p where p.id = parcel_id and p.user_id = auth.uid()));

alter publication supabase_realtime add table public.parcel_timeline_events;


-- ============================================================================
-- RIDES  (small reference/catalog tables backing the ride-matching mock)
-- ============================================================================

create table public.ride_options (
  id           uuid primary key default gen_random_uuid(),
  vehicle_type text not null check (vehicle_type in ('Moto', 'Car')),
  eta_minutes  int not null,
  fare         numeric(10,2) not null,
  capacity     int not null
);

create table public.drivers (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  photo_path     text,
  rating         numeric(2,1) not null default 5.0 check (rating between 0 and 5),
  vehicle_type   text not null check (vehicle_type in ('Moto', 'Car')),
  vehicle_model  text not null,
  plate_number   text not null,
  eta_minutes    int not null default 5
);

alter table public.ride_options enable row level security;
alter table public.drivers enable row level security;

create policy "ride catalog is readable by signed-in users" on public.ride_options for select using (auth.role() = 'authenticated');
create policy "driver pool is readable by signed-in users" on public.drivers for select using (auth.role() = 'authenticated');


-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

create table public.notifications (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null references public.profiles (id) on delete cascade,
  module   text check (module in ('food', 'rides', 'logistics', 'shop', 'community')),
  icon     text not null,
  title    text not null,
  message  text not null,
  is_read  boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create policy "users manage their own notifications"
  on public.notifications for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter publication supabase_realtime add table public.notifications;

create table public.notification_preferences (
  user_id                    uuid primary key references public.profiles (id) on delete cascade,
  order_updates              boolean not null default true,
  promotions_and_deals       boolean not null default true,
  chat_messages              boolean not null default true,
  ride_and_delivery_updates  boolean not null default true,
  wallet_activity            boolean not null default true
);

alter table public.notification_preferences enable row level security;

create policy "users manage their own notification preferences"
  on public.notification_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Default preferences row the moment a profile is created.
create function public.handle_new_profile()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.notification_preferences (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_profile_created
  after insert on public.profiles
  for each row execute procedure public.handle_new_profile();


-- ============================================================================
-- CART  (food/shop carts persisted server-side so they survive app restarts)
-- ============================================================================

create table public.cart_items (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles (id) on delete cascade,
  kind              text not null check (kind in ('food', 'shop')),
  source_type       text not null check (source_type in ('menu_item', 'product')),
  source_id         uuid not null,                 -- menu_items.id or products.id, depending on source_type
  restaurant_name   text,                            -- set for kind='food'; the food cart can only ever hold one restaurant's dishes
  quantity          int not null default 1 check (quantity > 0),
  created_at        timestamptz not null default now()
);

alter table public.cart_items enable row level security;

create policy "users manage their own cart"
  on public.cart_items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Enforce "the food cart can only ever hold one restaurant" at the database
-- level too, not just in the app — a second line of defense behind the
-- client-side confirmation dialog. A plain unique index can't express this
-- (it would cap the cart at one *row*, not one *restaurant*), so it's a
-- trigger: reject an insert/update that would put a different restaurant's
-- dish alongside an existing one. The app is still expected to clear the
-- cart itself (see `replaceFoodCart` client-side) before switching
-- restaurants — this trigger only guards against that being skipped.
create function public.check_single_restaurant_food_cart()
returns trigger
language plpgsql
as $$
begin
  if new.kind = 'food' and exists (
    select 1 from public.cart_items
    where user_id = new.user_id
      and kind = 'food'
      and id <> new.id
      and restaurant_name is distinct from new.restaurant_name
  ) then
    raise exception 'Food cart already holds items from a different restaurant — clear it first.';
  end if;
  return new;
end;
$$;

create trigger enforce_single_restaurant_food_cart
  before insert or update on public.cart_items
  for each row execute procedure public.check_single_restaurant_food_cart();


-- ============================================================================
-- STORAGE  (buckets backing every *_path column above — this is what finally
-- lets the "Real photo swap point" comments in the Swift code get filled in)
-- ============================================================================

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),   -- profile photos — public read, so any Image URL just works
  ('catalog', 'catalog', true),   -- restaurant/menu/product/merchant photos — admin-uploaded, public read
  ('listings', 'listings', true); -- community listing photos — public read, owner-uploaded

create policy "avatar images are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "users upload their own avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users replace/delete their own avatar"
  on storage.objects for update using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users delete their own avatar"
  on storage.objects for delete
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "catalog images are publicly readable"
  on storage.objects for select
  using (bucket_id = 'catalog');
-- No insert/update/delete policy for `catalog`: upload from the Dashboard's
-- Storage browser (as an admin), same trust boundary as the catalog tables.

create policy "listing images are publicly readable"
  on storage.objects for select
  using (bucket_id = 'listings');

create policy "sellers upload their own listing photos"
  on storage.objects for insert
  with check (bucket_id = 'listings' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "sellers delete their own listing photos"
  on storage.objects for delete
  using (bucket_id = 'listings' and (storage.foldername(name))[1] = auth.uid()::text);

-- Upload convention for the two owner-scoped buckets: prefix every object
-- path with the uploader's own uid, e.g. `avatars/<uid>/profile.jpg` or
-- `listings/<uid>/<listing-id>/1.jpg` — that first path segment is exactly
-- what `storage.foldername(name)[1]` checks against auth.uid() above.


-- OneMart — wallet balance hardening
--
-- 0001's "users can update their own profile" policy technically lets a
-- signed-in client run `update profiles set wallet_balance = 99999`. This
-- trigger closes that hole: wallet_balance can now only change inside the
-- SECURITY DEFINER functions pay_from_wallet() / top_up_wallet() (which run
-- as the function owner, not as `authenticated`/`anon`). Name, phone, and
-- photo stay editable by the owner as before.

create function public.guard_wallet_balance()
returns trigger
language plpgsql
as $$
begin
  if new.wallet_balance is distinct from old.wallet_balance
     and current_user in ('authenticated', 'anon') then
    raise exception 'wallet_balance can only change through pay_from_wallet() or top_up_wallet()';
  end if;
  return new;
end;
$$;

create trigger guard_wallet_balance
  before update on public.profiles
  for each row execute procedure public.guard_wallet_balance();
