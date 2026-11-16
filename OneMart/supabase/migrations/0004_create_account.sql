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
