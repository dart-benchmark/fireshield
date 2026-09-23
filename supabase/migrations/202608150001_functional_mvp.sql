-- FireShield functional MVP: multi-tenant evidence, AI runs and findings.
-- Originals live in the private `assessment-artifacts` Storage bucket; these
-- tables hold metadata, versioned outputs and analytics-ready facts.

create extension if not exists pgcrypto;

create type public.fs_role as enum ('admin', 'orgadmin', 'manager', 'auditor', 'govt');
create type public.assessment_kind as enum ('site', 'plan');
create type public.assessment_status as enum ('draft', 'processing', 'review', 'complete', 'failed');
create type public.artifact_kind as enum ('site_image', 'plan_image', 'plan_pdf', 'overlay', 'dxf', 'json', 'report_pdf');

create table public.organisations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now()
);

create table public.organisation_members (
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.fs_role not null,
  primary key (organisation_id, user_id)
);

create table public.facilities (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  name text not null,
  occupancy_group text,
  profile jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.assessments (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  facility_id uuid references public.facilities(id) on delete set null,
  created_by uuid not null references public.profiles(id),
  kind public.assessment_kind not null,
  status public.assessment_status not null default 'draft',
  title text not null,
  building_profile jsonb not null default '{}'::jsonb,
  score numeric(5,2) check (score between 0 and 100),
  summary text,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.artifacts (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  kind public.artifact_kind not null,
  storage_path text not null unique,
  mime_type text not null,
  byte_size bigint not null check (byte_size >= 0),
  sha256 text,
  source_artifact_id uuid references public.artifacts(id),
  created_at timestamptz not null default now()
);

create table public.model_runs (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  provider text not null,
  model text not null,
  purpose text not null,
  model_version text,
  status text not null check (status in ('running', 'succeeded', 'failed')),
  input_artifact_ids uuid[] not null default '{}',
  output jsonb,
  error_code text,
  latency_ms integer,
  created_at timestamptz not null default now()
);

create table public.detections (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  model_run_id uuid references public.model_runs(id) on delete set null,
  type text not null,
  count integer not null default 1 check (count >= 0),
  condition text,
  label text,
  confidence numeric(4,3) check (confidence between 0 and 1),
  geometry jsonb,
  reviewed boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.findings (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  model_run_id uuid references public.model_runs(id) on delete set null,
  system text not null,
  status text not null check (status in ('compliant', 'gap', 'critical_gap', 'cannot_verify')),
  severity text not null check (severity in ('minor', 'major', 'critical')),
  observed text,
  required text,
  rationale text,
  reviewer_status text not null default 'pending' check (reviewer_status in ('pending', 'accepted', 'rejected', 'edited')),
  created_at timestamptz not null default now()
);

create table public.finding_citations (
  finding_id uuid not null references public.findings(id) on delete cascade,
  clause_id text not null,
  title text,
  page integer not null default 0,
  primary key (finding_id, clause_id, page)
);

create index assessments_org_created_idx on public.assessments (organisation_id, created_at desc);
create index assessments_facility_created_idx on public.assessments (facility_id, created_at desc);
create index findings_assessment_status_idx on public.findings (assessment_id, status, severity);
create index detections_assessment_type_idx on public.detections (assessment_id, type);

create or replace function public.can_access_org(target_org uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.organisation_members m
    where m.organisation_id = target_org and m.user_id = auth.uid()
  );
$$;

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
  insert into public.profiles (id, display_name)
    values (auth.uid(), coalesce(auth.jwt() ->> 'email', 'FireShield user'))
    on conflict (id) do nothing;
  insert into public.organisations (name) values (trim(org_name)) returning id into new_org_id;
  insert into public.organisation_members (organisation_id, user_id, role)
    values (new_org_id, auth.uid(), 'orgadmin');
  return new_org_id;
end;
$$;
revoke all on function public.create_organisation(text) from public;
grant execute on function public.create_organisation(text) to authenticated;

alter table public.organisations enable row level security;
alter table public.profiles enable row level security;
alter table public.organisation_members enable row level security;
alter table public.facilities enable row level security;
alter table public.assessments enable row level security;
alter table public.artifacts enable row level security;
alter table public.model_runs enable row level security;
alter table public.detections enable row level security;
alter table public.findings enable row level security;
alter table public.finding_citations enable row level security;

create policy profiles_self on public.profiles for all to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy organisations_member_read on public.organisations for select to authenticated
  using (public.can_access_org(id));
create policy memberships_member_read on public.organisation_members for select to authenticated
  using (public.can_access_org(organisation_id));
create policy facilities_member_all on public.facilities for all to authenticated
  using (public.can_access_org(organisation_id)) with check (public.can_access_org(organisation_id));
create policy assessments_member_all on public.assessments for all to authenticated
  using (public.can_access_org(organisation_id)) with check (public.can_access_org(organisation_id));
create policy artifacts_via_assessment on public.artifacts for all to authenticated
  using (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)))
  with check (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)));
create policy model_runs_via_assessment on public.model_runs for all to authenticated
  using (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)))
  with check (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)));
create policy detections_via_assessment on public.detections for all to authenticated
  using (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)))
  with check (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)));
create policy findings_via_assessment on public.findings for all to authenticated
  using (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)))
  with check (exists (select 1 from public.assessments a where a.id = assessment_id and public.can_access_org(a.organisation_id)));
create policy citations_via_finding on public.finding_citations for all to authenticated
  using (exists (
    select 1 from public.findings f join public.assessments a on a.id = f.assessment_id
    where f.id = finding_id and public.can_access_org(a.organisation_id)
  ))
  with check (exists (
    select 1 from public.findings f join public.assessments a on a.id = f.assessment_id
    where f.id = finding_id and public.can_access_org(a.organisation_id)
  ));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'assessment-artifacts',
  'assessment-artifacts',
  false,
  26214400,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf',
        'application/dxf', 'application/json', 'application/zip']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy assessment_artifacts_member_read on storage.objects
for select to authenticated
using (
  bucket_id = 'assessment-artifacts'
  and public.can_access_org(((storage.foldername(name))[1])::uuid)
);
create policy assessment_artifacts_member_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'assessment-artifacts'
  and public.can_access_org(((storage.foldername(name))[1])::uuid)
);
create policy assessment_artifacts_member_update on storage.objects
for update to authenticated
using (
  bucket_id = 'assessment-artifacts'
  and public.can_access_org(((storage.foldername(name))[1])::uuid)
)
with check (
  bucket_id = 'assessment-artifacts'
  and public.can_access_org(((storage.foldername(name))[1])::uuid)
);
create policy assessment_artifacts_member_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'assessment-artifacts'
  and public.can_access_org(((storage.foldername(name))[1])::uuid)
);

create or replace view public.facility_assessment_metrics
with (security_invoker = true)
as
select
  a.organisation_id,
  a.facility_id,
  date_trunc('month', a.completed_at) as month,
  count(*) as assessments,
  round(avg(a.score), 2) as average_score,
  count(*) filter (where f.status = 'critical_gap') as critical_gaps,
  count(*) filter (where f.status = 'gap') as gaps,
  count(*) filter (where f.status = 'cannot_verify') as cannot_verify
from public.assessments a
left join public.findings f on f.assessment_id = a.id
where a.status = 'complete'
group by a.organisation_id, a.facility_id, date_trunc('month', a.completed_at);

-- Object names must be organisation_id/assessment_id/file-name.ext so Storage
-- RLS and relational assessment membership agree.
