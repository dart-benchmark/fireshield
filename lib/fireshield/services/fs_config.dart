/// Runtime configuration for the FireShield AI services.
///
/// The Cloudflare Worker URL is injected at build time so it never has to be
/// hard-coded, and the Groq key never lives in the app at all:
///
///   flutter run   -t lib/fireshield_main.dart -d chrome \
///     --dart-define=FIRESHIELD_WORKER_URL=https://fireshield-groq-gateway.<sub>.workers.dev
///   flutter build web -t lib/fireshield_main.dart --release \
///     --dart-define=FIRESHIELD_WORKER_URL=https://…workers.dev --base-href /<repo>/
library;

/// Base URL of the deployed Worker gateway. Empty when not configured — the AI
/// features then surface an explicit "not configured" state instead of faking
/// results.
const String workerBaseUrl = String.fromEnvironment('FIRESHIELD_WORKER_URL',
    defaultValue: 'https://fireshield-groq-gateway.thevikram123.workers.dev');

bool get isWorkerConfigured => workerBaseUrl.isNotEmpty;

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://dhchsufskqecoelrdhwa.supabase.co');
const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_G9MwIp8usNm-7povOkNLWg_fFqubU9L');

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
