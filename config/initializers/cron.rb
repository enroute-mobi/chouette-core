Cron.every_5_minutes :check_import_operations, :check_ccset_operations, :check_nightly_aggregates, :handle_dead_workers
Cron.every_day_at_3AM :purge_workgroups, :purge_referentials, :retrieve_all_sources, :audit_referentials
