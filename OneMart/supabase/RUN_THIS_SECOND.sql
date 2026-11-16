-- ============================================================================
-- OneMart — STEP 2: instant sign-up/login + demo account
--
-- Run AFTER RUN_THIS_ONCE.sql: Supabase Dashboard → SQL Editor → New query →
-- paste this whole file → Run. Safe to run any number of times.
--
-- Demo login →  raiden@demo.com  /  password123   (₱1,000 wallet)
--
-- Combines: migrations/0003_auto_confirm.sql + migrations/0004_create_account.sql
--           + seed_demo_account.sql (plus a profile backfill below).
-- ============================================================================

do $$
begin
  if to_regclass('public.profiles') is null then
    raise exception 'Run RUN_THIS_ONCE.sql first — the OneMart tables don''t exist yet.';
  end if;
end;
$$;

-- Accounts created before RUN_THIS_ONCE.sql was run have no profile row,
-- which makes login fail right after the password check. Create the missing
-- ones (name falls back to the part of the email before the @).
insert into public.profiles (id, name, phone)
select u.id,
       coalesce(nullif(u.raw_user_meta_data ->> 'name', ''), split_part(u.email, '@', 1)),
       coalesce(u.raw_user_meta_data ->> 'phone', '')
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);

-- OneMart — instant login after sign-up
--
-- Marks every new account's email as confirmed the moment it's created, so
-- a freshly signed-up user can log in immediately even if the project's
-- "Confirm email" setting is still on. (Turning that setting off in
-- Authentication → Sign In / Providers → Email is still recommended — it
-- also stops Supabase from trying to SEND the confirmation email, which on
-- the free built-in mailer is limited to a few per hour and makes sign-up
-- fail with "email rate limit exceeded" once you hit it.)
--
-- Safe to run more than once.

create or replace function public.auto_confirm_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists auto_confirm_new_user on auth.users;
create trigger auto_confirm_new_user
  before insert on auth.users
  for each row execute procedure public.auto_confirm_new_user();

-- Also confirm anyone who already signed up before this ran.
update auth.users set email_confirmed_at = now() where email_confirmed_at is null;


-- OneMart — email-free sign-up
--
-- Supabase Auth's normal sign-up sends a confirmation email whenever the
-- project's "Confirm email" setting is on, and the free built-in mailer only
-- allows a few emails per hour — after that every sign-up fails with
-- "email rate limit exceeded".
--
-- The app now creates accounts through this function instead: it writes an
-- already-confirmed user straight into auth.users (bcrypt-hashed password,
-- same as Supabase Auth itself), so no email is ever sent, then the app logs
-- in with the same email + password. The `on_auth_user_created` trigger from
-- 0001 still creates the matching `profiles` row automatically.
--
-- Safe to run more than once.

create or replace function public.create_account(
  p_email text,
  p_password text,
  p_name text,
  p_phone text default ''
)
returns void
language plpgsql
security definer set search_path = public, extensions
as $$
declare
  v_id    uuid := gen_random_uuid();
  v_email text := lower(trim(p_email));
begin
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address.';
  end if;
  if coalesce(length(p_password), 0) < 8 then
    raise exception 'Password must be at least 8 characters.';
  end if;
  if coalesce(trim(p_name), '') = '' then
    raise exception 'Full name is required.';
  end if;
  if exists (select 1 from auth.users where lower(email) = v_email) then
    raise exception 'An account with this email already exists. Try logging in instead.';
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, recovery_token, email_change, email_change_token_new,
    email_change_token_current, phone_change, phone_change_token, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
    v_email, extensions.crypt(p_password, extensions.gen_salt('bf', 10)),
    now(), '{"provider":"email","providers":["email"]}',
    jsonb_build_object('name', trim(p_name), 'phone', coalesce(trim(p_phone), '')),
    now(), now(),
    '', '', '', '', '', '', '', ''
  );

  insert into auth.identities (
    provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values (
    v_id::text, v_id,
    jsonb_build_object('sub', v_id::text, 'email', v_email, 'email_verified', true),
    'email', now(), now(), now()
  );
end;
$$;

revoke all on function public.create_account(text, text, text, text) from public;
grant execute on function public.create_account(text, text, text, text) to anon, authenticated;


-- OneMart — demo account (create OR repair)
--
--   Email:    raiden@demo.com   (logging in as "Raiden@demo.com" works too)
--   Password: password123
--
-- If the account doesn't exist yet, it's created already-confirmed with
-- ₱1,000.00 in its OneMart Wallet.
--
-- If it DOES exist (e.g. someone tried signing up as raiden@demo.com in the
-- app earlier and it got stuck unconfirmed, or with a different password),
-- it's repaired instead: password reset to password123, email confirmed,
-- login identity and profile row restored. Safe to run any number of times.

do $$
declare
  v_id uuid;
begin
  select id into v_id from auth.users where lower(email) = 'raiden@demo.com' limit 1;

  if v_id is null then
    v_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change, email_change_token_new,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
      'raiden@demo.com', extensions.crypt('password123', extensions.gen_salt('bf', 10)),
      now(), '{"provider":"email","providers":["email"]}',
      '{"name":"Raiden","phone":"09171234567"}',
      now(), now(),
      '', '', '', '', '', '', '', ''
    );

    -- Starting wallet balance, with a matching ledger row so the Wallet
    -- screen's history explains where the money came from.
    update public.profiles set wallet_balance = 1000 where id = v_id;
    insert into public.wallet_transactions (user_id, module, type, title, subtitle, amount, payment_method)
    values (v_id, null, 'Top Up', 'Wallet Top-Up', 'Demo starting balance', 1000, 'GCash');
  else
    update auth.users set
      email                      = 'raiden@demo.com',
      encrypted_password         = extensions.crypt('password123', extensions.gen_salt('bf', 10)),
      email_confirmed_at         = coalesce(email_confirmed_at, now()),
      aud                        = coalesce(aud, 'authenticated'),
      role                       = coalesce(role, 'authenticated'),
      instance_id                = coalesce(instance_id, '00000000-0000-0000-0000-000000000000'),
      raw_app_meta_data          = coalesce(raw_app_meta_data, '{"provider":"email","providers":["email"]}'),
      confirmation_token         = '',
      recovery_token             = '',
      email_change               = '',
      email_change_token_new     = '',
      email_change_token_current = '',
      phone_change               = coalesce(phone_change, ''),
      phone_change_token         = '',
      reauthentication_token     = '',
      banned_until               = null,
      updated_at                 = now()
    where id = v_id;

    -- Restore the profile row if it's missing (account created before the
    -- schema was set up).
    insert into public.profiles (id, name, phone)
    values (v_id, 'Raiden', '09171234567')
    on conflict (id) do nothing;

    -- Give the repaired demo account its starting ₱1,000 if it never had
    -- any wallet activity.
    if not exists (select 1 from public.wallet_transactions where user_id = v_id) then
      update public.profiles set wallet_balance = 1000 where id = v_id;
      insert into public.wallet_transactions (user_id, module, type, title, subtitle, amount, payment_method)
      values (v_id, null, 'Top Up', 'Wallet Top-Up', 'Demo starting balance', 1000, 'GCash');
    end if;
  end if;

  -- Make sure the email/password login identity exists.
  insert into auth.identities (
    provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values (
    v_id::text, v_id,
    jsonb_build_object('sub', v_id::text, 'email', 'raiden@demo.com', 'email_verified', true),
    'email', now(), now(), now()
  )
  on conflict (provider_id, provider) do update
    set identity_data = excluded.identity_data, updated_at = now();
end;
$$;
