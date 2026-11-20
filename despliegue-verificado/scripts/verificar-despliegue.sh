#!/usr/bin/env bash
# Verificación rápida de un despliegue HTTP.
# Uso: verificar-despliegue.sh https://api.ejemplo.com [version-esperada] [ruta-salud]
# Solo hace peticiones GET/HEAD. No modifica nada.
set -uo pipefail

URL="${1:?Uso: $0 URL [version-esperada] [ruta-salud]}"
ESPERADA="${2:-}"
SALUD="${3:-/health}"
URL="${URL%/}"
fallos=0

ok()    { printf '  \033[32mOK\033[0m    %s\n' "$1"; }
falla() { printf '  \033[31mFALLA\033[0m %s\n' "$1"; fallos=$((fallos+1)); }

echo "Verificando $URL"

# 1. HTTPS y certificado
if curl -sS -o /dev/null --max-time 20 "$URL"; then ok "responde por HTTPS con certificado válido"
else falla "no responde o el certificado no es válido"; fi

host=$(printf '%s' "$URL" | sed -E 's#^https?://([^/:]+).*#\1#')
if command -v openssl >/dev/null; then
  vence=$(echo | openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  [ -n "$vence" ] && ok "certificado vence: $vence"
fi

# 2. Salud y versión
cuerpo=$(curl -sS --max-time 60 -w '\n%{http_code}' "$URL$SALUD" 2>/dev/null)
codigo=$(printf '%s' "$cuerpo" | tail -n1)
cuerpo=$(printf '%s' "$cuerpo" | sed '$d')
if [ "$codigo" = "200" ]; then ok "$SALUD → 200"
else falla "$SALUD → ${codigo:-sin respuesta}"; fi

if [ -n "$ESPERADA" ]; then
  if printf '%s' "$cuerpo" | grep -q -- "$ESPERADA"; then ok "versión desplegada contiene '$ESPERADA'"
  else falla "no se encontró la versión '$ESPERADA' en $SALUD (¿se desplegó otra rama o sigue el build?)"; fi
fi

# 3. Cabeceras básicas de seguridad
cab=$(curl -sSI --max-time 20 "$URL" 2>/dev/null | tr -d '\r')
for h in strict-transport-security x-content-type-options; do
  if printf '%s' "$cab" | grep -qi "^$h:"; then ok "cabecera $h presente"
  else falla "falta cabecera $h"; fi
done
if printf '%s' "$cab" | grep -qi '^x-powered-by:'; then falla "expone x-powered-by"; fi

# 4. Tiempo de respuesta
t=$(curl -sS -o /dev/null --max-time 60 -w '%{time_total}' "$URL$SALUD" 2>/dev/null || echo "?")
ok "tiempo de $SALUD: ${t}s"

echo
if [ "$fallos" -eq 0 ]; then echo "Sin fallos. Falta la prueba de humo de los flujos críticos y revisar los logs."
else echo "$fallos verificación(es) fallaron."; exit 1; fi
