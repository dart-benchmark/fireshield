-- `rls_auto_enable` is an internal SECURITY DEFINER helper and must not be an
-- externally callable Data API RPC. FireShield does not invoke it at runtime.
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
grant execute on function public.rls_auto_enable() to postgres, service_role;
