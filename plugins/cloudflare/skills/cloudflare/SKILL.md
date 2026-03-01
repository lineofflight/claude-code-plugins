---
name: cloudflare
description: Manages Cloudflare zones via API. Use when purging cache, querying DNS records, or checking zone analytics.
allowed-tools: Bash(curl https://api.cloudflare.com/*), Bash(jq *)
argument-hint: "purge | dns | analytics | list-zones [zone]"
---

# Cloudflare API

## Authentication

All requests use Bearer token auth:

```
-H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json"
```

## Common operations

List zones:
```
GET https://api.cloudflare.com/client/v4/zones
```

Purge cached URLs:
```
POST https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache
Body: {"files":["https://example.com/path/to/asset"]}
```

DNS records:
```
GET https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records
```

Analytics (last 24h):
```
POST https://api.cloudflare.com/client/v4/graphql
Body: {"query":"{ viewer { zones(filter: {zoneTag: \"ZONE_ID\"}) { httpRequests1dGroups(limit: 1, filter: {date_geq: \"YYYY-MM-DD\"}) { sum { requests pageViews bytes threats } } } } }"}
```
Set `date_geq` to yesterday's date. Adapt the query for other datasets — see [Cloudflare GraphQL Analytics docs](https://developers.cloudflare.com/analytics/graphql-api/).

## Notes

- Always look up the zone ID first if not provided
- Use `jq` to format responses
- Keep output concise — summarize rather than dump raw JSON
