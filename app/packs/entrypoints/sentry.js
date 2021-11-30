import * as Sentry from "@sentry/browser";
import { Integrations } from "@sentry/tracing";

let browser_environment = fetch("/api/v1/browser_environment.json")
  .then((res) => res.json())
  .then((browser_environment) => {
    Sentry.init({
      dsn: browser_environment["dsn"],

      // Alternatively, use `process.env.npm_package_version` for a dynamic release version
      // if your build tool supports it.
      //release: process.env.npm_package_version,
      environment: browser_environment["environment"],
      integrations: [new Integrations.BrowserTracing()],

      // Set tracesSampleRate to 1.0 to capture 100%
      // of transactions for performance monitoring.
      // We recommend adjusting this value in production
      tracesSampleRate: 1.0,
    });

    Sentry.setTag("service", browser_environment["app"] + "-" + browser_environment["context"]);
  })
  .catch((error) => {
    console.error('Error:', error)
  })
