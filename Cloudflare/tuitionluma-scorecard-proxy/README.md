# TuitionLuma College Scorecard Proxy

Cloudflare Worker proxy for TuitionLuma's College Scorecard API traffic.

The iOS app calls:

- `GET https://api.tuitionluma.com/schools`
- `GET https://api.tuitionluma.com/school`
- `GET https://api.tuitionluma.com/programs`

The Worker forwards those requests to College Scorecard, injects the API key from a Cloudflare secret, and returns the original College Scorecard JSON shape unchanged.

## Deploy

1. Install Wrangler:

   ```bash
   npm install -g wrangler
   ```

2. Sign in to Cloudflare:

   ```bash
   wrangler login
   ```

3. Add the College Scorecard API key as a Worker secret:

   ```bash
   cd Cloudflare/tuitionluma-scorecard-proxy
   wrangler secret put COLLEGE_SCORECARD_API_KEY
   ```

4. Deploy:

   ```bash
   wrangler deploy
   ```

5. In Cloudflare DNS, make sure `api.tuitionluma.com` is proxied through Cloudflare and routed to this Worker. If the domain or zone name differs, update `wrangler.toml` before deploying.

## Verify

```bash
curl "https://api.tuitionluma.com/schools?school.name=Rice&fields=id,school.name,school.city,school.state&page=0&per_page=1"
curl "https://api.tuitionluma.com/school?id=227757&fields=id,school.name&page=0&per_page=1"
curl "https://api.tuitionluma.com/programs?id=227757&fields=id,latest.programs.cip_4_digit&all_programs_nested=true&page=0&per_page=1"
```

## Behavior

- 24 hour cache for successful `GET` responses.
- Incoming `api_key` query parameters are ignored.
- Basic in-memory per-IP rate limiting protects the Worker from bursts.
- Store `COLLEGE_SCORECARD_API_KEY` only as a Cloudflare secret.
- For stronger production rate limits, add Cloudflare WAF rules or a Durable Object backed limiter.
