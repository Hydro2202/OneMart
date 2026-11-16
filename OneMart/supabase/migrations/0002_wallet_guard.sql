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
