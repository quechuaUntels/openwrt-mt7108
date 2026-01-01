#!/bin/bash

# 1. Definir la ruta del repositorio (un nivel arriba de donde estamos)
RR="${GITHUB_WORKSPACE:-$(dirname "$PWD")}"

# 1. PREPARACIÓN DE RUTAS
mkdir -p target/linux/gemini/dts/
mkdir -p files/etc/Wireless/RT2870AP/
mkdir -p files/lib/firmware/
mkdir -p target/linux/gemini/image/

# 2. INYECCIÓN DE ARCHIVOS FÍSICOS
if [ -f "$RR/hw/rt2870.bin" ]; then
    cp -f "$RR/hw/rt2870.bin" files/etc/Wireless/RT2870AP/rt2870.bin
    cp -f "$RR/hw/rt2870.bin" files/lib/firmware/rt2870.bin
fi

[ -f "$RR/hw/RT2870AP.dat" ] && cp -f "$RR/hw/RT2870AP.dat" files/etc/Wireless/RT2870AP/RT2870AP.dat
[ -f "$RR/hw/mt7108.dtsi" ] && cp -f "$RR/hw/mt7108.dtsi" target/linux/gemini/dts/
[ -f "$RR/hw/mt7119-seowon.dts" ] && cp -f "$RR/hw/mt7119-seowon.dts" target/linux/gemini/dts/

# 3. REGISTRO DEL DISPOSITIVO (Crucial para que coincida con seed.config)
# Este nombre 'seowon_swc9000' debe ser idéntico al de tu seed.config
if ! grep -q "Device/seowon_swc9000" target/linux/gemini/image/Makefile 2>/dev/null; then
echo "
define Device/seowon_swc9000
  DEVICE_VENDOR := Seowon
  DEVICE_MODEL := SWC9000
  DEVICE_DTS := mt7119-seowon
  SUPPORTED_DEVICES := seowon,swc9000
endef
TARGET_DEVICES += seowon_swc9000
" >> target/linux/gemini/image/Makefile
fi

# 4. LIMPIEZA Y CARGA DE CONFIGURACIÓN
if [ -f "$RR/seed.config" ]; then
    cat "$RR/seed.config" > .config
    yes "" | make oldconfig
else
    echo "ERROR CRÍTICO: No se encontró el archivo de configuración en $RR"
    exit 1
fi
