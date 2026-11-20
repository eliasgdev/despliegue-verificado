# Notas por proveedor

## Render (backends Node, workers, cron)

- `Build Command`: `npm ci && npm run build` (o solo `npm ci`). `Start Command`: `node src/index.js` o `npm start`.
- Escuchar en `process.env.PORT` y en `0.0.0.0`.
- Health check path: `/health`. Sin él, Render considera "vivo" un proceso que no responde.
- Auto-deploy por rama: saber qué rama despliega cada servicio (muchas veces `main`, no `develop`).
- Migraciones: comando previo al despliegue (*pre-deploy command*) o paso explícito; nunca dentro del arranque de cada instancia si hay varias.
- El plan gratuito suspende el servicio: la primera petición puede tardar 30–60 s; no confundir con caída.
- Variables: en *Environment*; un cambio de variable redepliega el servicio.

## Netlify (sitios estáticos y SPA)

- Reglas de SPA en `netlify.toml` o `_redirects`: `/*  /index.html  200`. Con prerender, una regla por ruta o asegurarse de que cada ruta generó su HTML.
- Las variables de entorno del build se **incrustan** en el bundle: nunca poner secretos de backend ahí.
- Fusionar a la rama de producción publica; los PR generan *deploy previews*: revisar el preview antes de fusionar.
- Rollback: *Deploys* → elegir un deploy anterior → *Publish deploy*.
- Cabeceras de seguridad y caché en `netlify.toml` (`[[headers]]`); los assets con hash pueden ser `immutable`, el `index.html` no.

## Vercel

- Similar a Netlify: variables por entorno (Production / Preview / Development), previews por PR, `vercel.json` para reescrituras y cabeceras.
- Funciones serverless con límites de tiempo: no hacer trabajos largos ahí.

## Cloudflare Workers / Pages

- `wrangler deploy` para Workers; secretos con `wrangler secret put NOMBRE` (no en `wrangler.toml`).
- Revisar `compatibility_date` y los bindings (KV, D1, R2) por entorno.
- Rutas y dominios personalizados: confirmar que el DNS está *proxied* (nube naranja) cuando el Worker debe interceptar.
- Rollback: `wrangler rollback` o desde el panel (*Deployments*).

## Neon / Supabase (Postgres administrado)

- Usar la URL del **pooler** para apps con muchas conexiones cortas (serverless); la directa para migraciones.
- `sslmode=require` y verificación del certificado cuando el cliente lo permita.
- Crear una **rama** de la base para probar migraciones con datos reales y borrarla después.
- Point-in-time restore: saber cuál es la ventana de retención del plan antes de necesitarla.

## VMs (Azure, AWS, DigitalOcean)

- Servicio gestionado por `systemd` (reinicio automático, logs en `journalctl -u servicio`), no un `node` corriendo en una terminal.
- Proxy inverso (Nginx/Caddy) con HTTPS; la app solo escucha en `127.0.0.1`.
- Firewall: abrir solo 80/443 (y SSH restringido por IP o por llave). La base de datos nunca expuesta a Internet.
- Despliegue repetible con un script (`git pull`, `npm ci`, migraciones, `systemctl restart`) y un script de auditoría que revise servicios activos, puertos abiertos, espacio en disco y certificados.
- Actualizaciones de seguridad del sistema y respaldos programados fuera de la VM.

## DNS y dominios

- Bajar el TTL antes de un cambio de DNS planeado.
- Verificar con `dig +short dominio` y `curl -I https://dominio` desde fuera, no solo desde el navegador con caché.
- Certificado: confirmar fecha de vencimiento y renovación automática.
