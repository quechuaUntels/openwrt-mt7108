#!/bin/bash

# 1. Definir la ruta del repositorio (un nivel arriba de donde estamos)
RR="$(dirname "$PWD")"

# 1. PREPARACIÓN DE RUTAS
# Creamos las carpetas necesarias para el hardware y el firmware de la radio
mkdir -p target/linux/gemini/dts/
mkdir -p files/etc/Wireless/RT2870AP/
mkdir -p files/lib/firmware/

# 2. INYECCIÓN DE ARCHIVOS FÍSICOS
if [ -f $RR/hw/rt2870.bin ]; then
    # Copia a la ruta legacy (tu hardware)
    cp -f "$RR/hw/rt2870.bin" files/etc/Wireless/RT2870AP/rt2870.bin
    # Copia a la ruta estándar (OpenWrt 2026)
    cp -f "$RR/hw/rt2870.bin" files/lib/firmware/rt2870.bin
else
    echo "ERROR CRÍTICO: No se encontró el archivo de configuración en $RR"
    exit 1
fi

# 1. Inyectar archivos usando la ruta absoluta del workspace
[ -f "$RR/hw/RT2870AP.dat" ] && cp -f "$RR/hw/RT2870AP.dat" files/etc/Wireless/RT2870AP/RT2870AP.dat
[ -f "$RR/hw/mt7108.dtsi" ] && cp -f "$RR/hw/mt7108.dtsi" target/linux/gemini/dts/
[ -f "$RR/hw/mt7119-seowon.dts" ] && cp -f "$RR/hw/mt7119-seowon.dts" target/linux/gemini/dts/

# 3. REGISTRO DEL DISPOSITIVO (Crucial para que coincida con seed.config)
# Este nombre 'seowon_swc9000' debe ser idéntico al de tu seed.config
echo "
define Device/seowon_swc9000
  DEVICE_VENDOR := Seowon
  DEVICE_MODEL := SWC9000
  DEVICE_DTS := mt7119-seowon
  SUPPORTED_DEVICES := seowon,swc9000
endef
TARGET_DEVICES += seowon_swc9000
" >> target/linux/gemini/image/Makefile

# 4. LIMPIEZA Y CARGA DE CONFIGURACIÓN
# Sustituimos cualquier configuración previa por tu seed.config íntegro
[ -f "$RR/seed.config" ] && cat "$RR/seed.config" > .config

# 5. VALIDACIÓN NO INTERACTIVA
# Aplicamos la configuración y forzamos que el sistema no se detenga por avisos
make oldconfig
