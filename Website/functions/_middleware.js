export async function onRequest(context) {
  const { request, env, next } = context;
  const path = new URL(request.url).pathname;
  const isProtected = path.startsWith("/admin/") || path === "/api/growth";

  if (!isProtected) {
    return next();
  }

  const username = env.GROWTH_ADMIN_USERNAME;
  const password = env.GROWTH_ADMIN_PASSWORD;

  if (!username || !password) {
    return next();
  }

  const authorization = request.headers.get("authorization") || "";
  const [scheme, encoded] = authorization.split(" ");

  if (scheme !== "Basic" || !encoded) {
    return unauthorized();
  }

  let decoded = "";
  try {
    decoded = atob(encoded);
  } catch {
    return unauthorized();
  }

  const separator = decoded.indexOf(":");
  const suppliedUsername = decoded.slice(0, separator);
  const suppliedPassword = decoded.slice(separator + 1);

  if (suppliedUsername !== username || suppliedPassword !== password) {
    return unauthorized();
  }

  return next();
}

function unauthorized() {
  return new Response("Authentication required.", {
    status: 401,
    headers: {
      "www-authenticate": 'Basic realm="TuitionLuma Growth"',
      "cache-control": "no-store",
      "x-robots-tag": "noindex, nofollow, noarchive"
    }
  });
}
