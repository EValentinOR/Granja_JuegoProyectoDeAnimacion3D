import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "POST required." }, 405);

  const projectUrl = Deno.env.get("SUPABASE_URL");
  const apiKey = request.headers.get("apikey") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = request.headers.get("Authorization");
  if (!projectUrl || !apiKey || !serviceRoleKey || !authorization?.startsWith("Bearer ")) {
    return json({ error: "Missing Supabase configuration or user session." }, 401);
  }

  const userClient = createClient(projectUrl, apiKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: authorization } },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser(authorization.slice("Bearer ".length));
  if (authError || !authData.user) return json({ error: "Invalid user session." }, 401);

  const admin = createClient(projectUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  let body: { game_id?: unknown; state?: unknown };
  try {
    body = await request.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }

  const gameId = String(body.game_id ?? "").trim().toLowerCase();
  if (!/^[0-9a-f]{32}$/.test(gameId)) return json({ error: "Invalid game ID." }, 400);
  const action = new URL(request.url).searchParams.get("action");

  if (action === "load_by_id") {
    const { data, error } = await admin
      .from("shared_game_saves")
      .select("state")
      .eq("game_id", gameId)
      .maybeSingle();
    if (error) return json({ error: error.message }, 500);
    if (!data) return json({ error: "Save not found." }, 404);
    return json({ state: data.state });
  }

  if (action !== "save") return json({ error: "Unsupported action." }, 404);
  if (!body.state || typeof body.state !== "object" || Array.isArray(body.state)) {
    return json({ error: "State must be a JSON object." }, 400);
  }
  const { error } = await admin.from("shared_game_saves").upsert({
    game_id: gameId,
    state: body.state,
    created_by: authData.user.id,
    updated_at: new Date().toISOString(),
  }, { onConflict: "game_id" });
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true });
});
