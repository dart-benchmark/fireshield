-- Follow-up from Supabase security/performance advisors.
revoke execute on function public.can_access_org(uuid) from public, anon;
revoke execute on function public.create_organisation(text) from public, anon;
grant execute on function public.can_access_org(uuid) to authenticated, service_role;
grant execute on function public.create_organisation(text) to authenticated, service_role;

create index artifacts_assessment_idx on public.artifacts (assessment_id);
create index artifacts_source_idx on public.artifacts (source_artifact_id) where source_artifact_id is not null;
create index assessments_created_by_idx on public.assessments (created_by);
create index detections_model_run_idx on public.detections (model_run_id) where model_run_id is not null;
create index facilities_org_idx on public.facilities (organisation_id);
create index findings_model_run_idx on public.findings (model_run_id) where model_run_id is not null;
create index model_runs_assessment_idx on public.model_runs (assessment_id);
create index organisation_members_user_idx on public.organisation_members (user_id);

drop policy profiles_self on public.profiles;
create policy profiles_self on public.profiles for all to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
