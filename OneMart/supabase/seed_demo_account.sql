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
