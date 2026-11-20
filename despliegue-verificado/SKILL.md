---
name: despliegue-verificado
description: Desplegar a producción sin sorpresas y comprobar que de verdad quedó funcionando. Úsala cuando se vaya a desplegar, publicar, hacer un release, fusionar a main con despliegue automático, correr migraciones en producción, agregar variables de entorno, configurar un dominio o DNS, o cuando pidan "sube a producción", "despliega", "¿ya quedó en vivo?", "verifica el despliegue", "rollback" o "se cayó producción". Pensada para Render, Netlify, Vercel, Cloudflare Workers/Pages, Neon/Supabase y VMs (Azure, AWS, DigitalOcean).
---

# Despliegue verificado

Un despliegue no está terminado cuando el pipeline sale en verde: está terminado cuando **se comprobó en producción** que la versión nueva responde y que el cambio se ve. Nunca decir "ya quedó" sin esa evidencia.

## Las tres fases

### 1. Antes (en local o staging)

- [ ] Pruebas y build en verde **con el mismo comando que usa el servidor** (`npm ci && npm run build`, no `npm install`).
- [ ] Variables de entorno nuevas listadas y **ya creadas** en el proveedor antes del deploy (no después del primer error).
- [ ] Migraciones de base de datos **compatibles hacia atrás**: la versión vieja del código tiene que seguir funcionando con el esquema nuevo mientras se despliega (agregar columna nula → desplegar → rellenar → volver obligatoria; nunca renombrar o borrar en el mismo paso).
- [ ] Probadas contra una copia o rama de la base (Neon y Supabase tienen ramas; en una VM, un dump restaurado).
- [ ] Respaldo o punto de restauración de la base antes de una migración destructiva.
- [ ] Saber **cómo volver atrás**: versión anterior identificada (commit, deploy o tag) y si la migración tiene reversa.
- [ ] Si fusionar a `main` despliega solo (Netlify, Vercel, Render con auto-deploy), tratar el merge como el despliegue.

### 2. Durante

- Desplegar **un servicio a la vez** en el orden correcto: base de datos (migración) → backend → frontend.
- Seguir el log del build y del arranque hasta ver el servidor escuchando; no asumir.
- Si el proveedor tiene health check, configurarlo en una ruta real (`/health`) que toque la base de datos.

### 3. Después: verificar con evidencia

Comprobar **la versión nueva**, no "algo responde":

1. **Versión**: el endpoint de salud o una cabecera devuelve el commit o la versión desplegada (`/health` → `{ ok: true, version: "abc1234" }`). Si no existe, crearlo.
2. **Prueba de humo**: los 3–5 flujos críticos (login, la pantalla principal, la acción que cambió) con `curl` o el navegador real.
3. **El cambio concreto**: ver en producción lo que cambió (el texto nuevo, la ruta nueva, el 401 del webhook sin firma, etc.).
4. **Frontend**: cargar sin caché; revisar consola del navegador y peticiones fallidas. En PWA, confirmar que el service worker tomó la versión nueva.
5. **Logs** de los primeros minutos sin errores nuevos.
6. **Reportar** con la evidencia: qué se verificó, con qué comando y qué respondió.

`scripts/verificar-despliegue.sh URL [VERSION_ESPERADA]` hace los puntos 1 y parte del 2 para APIs HTTP.

## Rollback

- Fallo de código sin migración → volver al deploy anterior desde el panel del proveedor (lo más rápido) y después corregir con un PR.
- Fallo con migración aplicada → si la migración era compatible hacia atrás, basta volver el código. Si no lo era, restaurar el respaldo **solo** si no hay escrituras nuevas que perder; si las hay, corregir hacia adelante.
- Escribir qué pasó y qué se cambió para que no vuelva a pasar.

## Errores frecuentes

| Síntoma | Causa habitual |
|---|---|
| Funciona en local, 500 en producción | Variable de entorno faltante o con otro nombre |
| Rutas del frontend dan 404 al recargar | Falta la regla de reescritura de SPA |
| CORS bloquea en producción | Dominio de producción no está en la lista permitida |
| La base rechaza la conexión | SSL requerido, IP no permitida o límite de conexiones (usar el pooler) |
| El cambio "no se ve" | Caché del CDN o del service worker; o se desplegó otra rama |
| El servicio se duerme / tarda en la primera petición | Plan gratuito con suspensión por inactividad |

Detalle por proveedor en `references/proveedores.md`.
