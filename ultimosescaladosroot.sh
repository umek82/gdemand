```bash
#!/bin/bash

# Consulta los ultimos usuarios que han escalado a root
# Compatible con RHEL 7, 8 y 9
# Uso: ./ultimos_escalados_root.sh [numero_registros]

LIMIT="${1:-20}"

if [[ ! "$LIMIT" =~ ^[0-9]+$ ]] || (( LIMIT < 1 )); then
    echo "Uso: $0 [numero_registros]"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta el script como root para consultar todos los registros."
    exit 1
fi

echo "=========================================================="
echo " ULTIMOS ESCALADOS A ROOT"
echo " Fecha de consulta: $(date '+%Y-%m-%d %H:%M:%S')"
echo " Servidor: $(hostname -f 2>/dev/null || hostname)"
echo "=========================================================="
echo

if [[ -r /var/log/secure ]]; then
    # Logs tradicionales de RHEL
    grep -hE 'sudo.*(COMMAND=|session opened for user root|USER=root)' \
        /var/log/secure /var/log/secure-* 2>/dev/null |
    awk '
    {
        fecha = $1 " " $2 " " $3
        linea = $0

        if (match(linea, /sudo[^:]*: [^ ]+ :/)) {
            usuario = substr(linea, RSTART, RLENGTH)
            sub(/^.*: /, "", usuario)
            sub(/ *:$/, "", usuario)
        } else {
            usuario = "desconocido"
        }

        if (match(linea, /COMMAND=.*/)) {
            comando = substr(linea, RSTART + 8)
        } else if (linea ~ /session opened for user root/) {
            comando = "Sesion root abierta"
        } else {
            comando = linea
        }

        printf "%s | Usuario: %-20s | %s\n", fecha, usuario, comando
    }' | tail -n "$LIMIT"

else
    # Alternativa si no existe /var/log/secure
    journalctl --no-pager -o short-iso 2>/dev/null |
    grep -E 'sudo.*(COMMAND=|session opened for user root|USER=root)' |
    tail -n "$LIMIT"
fi

echo
echo "NOTA: los registros dependen de la configuracion de auditoria"
echo "y de la retencion de logs del servidor."
```
