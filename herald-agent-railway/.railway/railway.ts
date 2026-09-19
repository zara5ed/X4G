/**
 * Herald · Railway Infrastructure as Code
 *
 * Railway deprecated Config as Code (railway.json / railway.toml): existing
 * files stop being read on 2026-12-01, and new services cannot opt into it.
 * This file is the current, supported format — see .railway/README.md.
 *
 *   railway config plan     # preview
 *   railway config apply    # apply
 *
 * `source` is deliberately omitted: connect this GitHub repository to the
 * service in the Railway dashboard (or with `railway link`), so the file stays
 * portable between forks and organizations.
 */
import { defineRailway, project, service, volume } from "railway/iac";

export default defineRailway(() => {
  // Agent memory, sessions, skills and credentials live here.
  // Sized at 1 GB, which is plenty for text-heavy agent state; Railway treats
  // an increase as a safe resize, while a decrease is destructive.
  const state = volume("herald-state", { sizeMB: 1024 });

  const agent = service("herald", {
    // Two gateways must never share one state directory.
    replicas: 1,

    // The container's Dockerfile CMD already starts the agent, so `start`
    // is intentionally left unset.
    volumeMounts: {
      "/opt/data": state,
    },

    env: {
      // HERMES_HOME and HOME are deliberately NOT overridden. The upstream
      // image already sets HERMES_HOME=/opt/data (the volume root) and mounts
      // it as VOLUME ["/opt/data"]; redefining it would put the agent's state
      // in a subdirectory that no upstream tooling or tutorial expects.
      HERALD_AGENT_NAME: "Herald",

      // Set HOME=/opt/data yourself if you want CLI caches (~/.config, npm,
      // .local/bin) to survive redeploys — upstream leaves HOME alone.
      PYTHONUNBUFFERED: "1",
      PYTHONDONTWRITEBYTECODE: "1",

      // Secrets are NOT defined here on purpose — keep credentials in the
      // Railway dashboard (or `railway variables --set`), never in Git:
      //   OPENROUTER_API_KEY / ANTHROPIC_API_KEY / OPENAI_API_KEY / GOOGLE_API_KEY
      //   TELEGRAM_BOT_TOKEN + TELEGRAM_ALLOWED_USERS (or DISCORD_* / SLACK_*)
    },
  });

  return project("herald-agent", {
    resources: [agent, state],
  });
});
