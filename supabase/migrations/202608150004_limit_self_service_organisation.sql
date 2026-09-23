-- Self-service registration provisions exactly one organisation for a new
-- authenticated user. Additional organisations require an admin workflow.
create or replace function public.create_organisation(org_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_org_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if length(trim(org_name)) < 2 then
    raise exception 'organisation name is required';
  end if;
  if exists (
    select 1 from public.organisation_members
    where user_id = auth.uid()
  ) then
    raise exception 'user already belongs to an organisation';
  end if;
  insert into public.profiles (id, display_name)
    values (auth.uid(), coalesce(auth.jwt() ->> 'email', 'FireShield user'))
    on conflict (id) do nothing;
  insert into public.organisations (name)
    values (trim(org_name)) returning id into new_org_id;
  insert into public.organisation_members (organisation_id, user_id, role)
    values (new_org_id, auth.uid(), 'orgadmin');
  return new_org_id;
end;
$$;

revoke all on function public.create_organisation(text) from public, anon;
grant execute on function public.create_organisation(text) to authenticated, service_role;
