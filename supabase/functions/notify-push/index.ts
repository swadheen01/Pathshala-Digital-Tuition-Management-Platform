import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  const webhookUrl = Deno.env.get("PUSH_WEBHOOK_URL");
  if (!webhookUrl) {
    return new Response("PUSH_WEBHOOK_URL is not configured", {
      status: 500,
      headers: corsHeaders,
    });
  }

  const payload = await request.json();
  if (!payload?.recipient_id || !payload?.title) {
    return new Response("recipient_id and title are required", {
      status: 400,
      headers: corsHeaders,
    });
  }

  const response = await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      recipientId: payload.recipient_id,
      title: payload.title,
      body: payload.body ?? "",
      type: payload.type,
      roomId: payload.room_id,
    }),
  });

  if (!response.ok) {
    return new Response(`Push provider returned ${response.status}`, {
      status: 502,
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ delivered: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
