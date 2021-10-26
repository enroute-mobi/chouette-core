import * as Sentry from "@sentry/browser";
import { Integrations } from "@sentry/tracing";

Sentry.init({
  dsn: process.env.SENTRY_DSN,

  // Alternatively, use `process.env.npm_package_version` for a dynamic release version
  // if your build tool supports it.
  release: process.env.npm_package_version,
  environment: process.env.SENTRY_ENVIRONMENT,
  integrations: [new Integrations.BrowserTracing()],

  // Set tracesSampleRate to 1.0 to capture 100%
  // of transactions for performance monitoring.
  // We recommend adjusting this value in production
  tracesSampleRate: 1.0,

});

Sentry.setTag("service", process.env.SENTRY_APP + "-" + process.env.SENTRY_CONTEXT);
