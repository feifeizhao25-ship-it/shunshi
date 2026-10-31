# End-to-end / harness scripts (box-run)

Scripts used to exercise the apps and APIs on the test box (Playwright against Flutter-web builds, plain HTTP batteries against the backends).
They were written for one machine: absolute paths such as `/workspace/ui_full_test/...` and `/workspace/fix2/...`, local ports and a Postgres/Redis on localhost
are hard-coded in the scripts and in the `start_*.sh` launchers. Adjust them before running elsewhere.

- `harness/` shared helpers: `fw.py` (Playwright helpers for Flutter web with semantics on), `edge.py` (local TLS proxy + static host), `spa.py` (static host),
  `gateway.py` / `oai_gw.py` (fake model gateways), `fakeredis_server.py`.
- `retest/` the before/after retest scripts and launchers for the 2026-10-31 round (`fix2_api_*.py` compare a base backend with the branch backend; `fix2_ui_*.py` take the screenshots).
- Test accounts in the scripts are made-up (example.com / example.cn, phone 138000000xx) and are created on a throw-away local database by the scripts themselves.
- No secrets: launchers generate random JWT/admin secrets per start; the model key (where used) is read from an environment variable and is never stored.
- The cf/energy AI calls need a reachable model provider; without one the generation endpoints answer 5xx and the batteries record that.
