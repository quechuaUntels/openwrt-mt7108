#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 1. PREPARACIÓN DE RUTAS
# Creamos las carpetas necesarias para el hardware y el firmware de la radio
mkdir -p target/linux/gemini/dts/
mkdir -p files/etc/Wireless/RT2870AP/
mkdir -p files/lib/firmware/

# 2. INYECCIÓN DE ARCHIVOS FÍSICOS
if [ -f ../hw/rt2870.bin ]; then
    # Copia a la ruta legacy (tu hardware)
    cp -f ../hw/rt2870.bin files/etc/Wireless/RT2870AP/rt2870.bin
    # Copia a la ruta estándar (OpenWrt 2026)
    cp -f ../hw/rt2870.bin files/lib/firmware/rt2870.bin
fi

[ -f ../hw/RT2870AP.dat ] && cp -f ../hw/files/RT2870AP.dat etc/Wireless/RT2870AP/RT2870AP.dat
[ -f ../hw/mt7108.dtsi ] && cp -f ../hw/mt7108.dtsi target/linux/gemini/dts/
[ -f ../hw/mt7119-seowon.dts ] && cp -f ../hw/mt7119-seowon.dts target/linux/gemini/dts/

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
cat ../seed.config > .config

# 5. VALIDACIÓN NO INTERACTIVA
# Aplicamos la configuración y forzamos que el sistema no se detenga por avisos
make oldconfig
