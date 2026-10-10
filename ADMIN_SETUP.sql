-- ARN Inventory • First Owner Admin Setup
-- Run AFTER the owner's account has been registered in Supabase Auth.
-- Replace the email with the exact owner email.
update public.arn_profiles p
set role='admin', updated_at=now()
from auth.users u
where u.id=p.id
  and lower(u.email)=lower('EMAIL_ADMIN_ANDA');

-- Check result:
select u.email,p.role,p.account_id
from auth.users u
join public.arn_profiles p on p.id=u.id
where lower(u.email)=lower('EMAIL_ADMIN_ANDA');
