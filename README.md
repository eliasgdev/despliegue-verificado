# Despliegue verificado

Skill para **Claude Code** que ordena los despliegues a producción en tres fases (antes, durante y después) y no da un despliegue por terminado hasta comprobar en producción que la versión nueva responde y que el cambio se ve.

Incluye notas por proveedor (Render, Netlify, Vercel, Cloudflare Workers/Pages, Neon/Supabase, VMs en Azure/AWS/DigitalOcean), una tabla de errores frecuentes, la estrategia de rollback y un script de verificación.

## Origen

Esta lista salió de desplegar y mantener varios sistemas propios y de clientes alojados en repositorios privados: backends en Render, sitios en Netlify y Cloudflare, bases en Neon y VMs en Azure. Cada punto de la lista corresponde a algo que alguna vez falló en producción, como una variable de entorno que faltaba, una SPA que daba 404 al recargar, un service worker con la versión vieja o una rama equivocada desplegada.

## Contenido

```
despliegue-verificado/
├── SKILL.md                       # fases, verificación con evidencia, rollback, errores frecuentes
├── references/
│   └── proveedores.md             # notas por proveedor, DNS y dominios
└── scripts/
    └── verificar-despliegue.sh    # HTTPS, certificado, /health, versión, cabeceras, tiempo (solo lectura)
```

## Instalación

```bash
git clone https://github.com/eliasgdev/despliegue-verificado.git
mkdir -p ~/.claude/skills
cp -r despliegue-verificado/despliegue-verificado ~/.claude/skills/
```

## Verificación sin Claude

```bash
bash despliegue-verificado/scripts/verificar-despliegue.sh https://api.tu-dominio.com abc1234
```

## Licencia

MIT
