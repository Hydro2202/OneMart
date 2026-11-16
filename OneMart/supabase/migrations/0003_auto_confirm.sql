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
