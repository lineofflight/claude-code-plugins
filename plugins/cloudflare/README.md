# Cloudflare

Manage Cloudflare zones via the API — purge cache, query DNS records, and check analytics.

## Setup

Set your API token as an environment variable:

```sh
export CLOUDFLARE_API_TOKEN=your_token_here
```

You can create a token at [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens). Grant it the **Zone:Read** and **Cache Purge** permissions for the zones you want to manage.

## Usage

Invoke the skill directly:

```
/cloudflare list-zones
/cloudflare purge example.com
/cloudflare dns example.com
/cloudflare analytics example.com
```

Or describe what you want and the skill will handle routing:

> Purge the cache for example.com/images/logo.png
