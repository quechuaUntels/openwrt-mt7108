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

# 1. Crear directorio de destino para el target Gemini (Kernel 6.6+)
mkdir -p target/linux/gemini/dts/

# 2. Copiar AMBOS archivos (dts y dtsi) a la carpeta del kernel
# Es vital que ambos estén juntos para que el preprocesador los encuentre
cp -f ../mt7108.dtsi target/linux/gemini/dts/
cp -f ../mt7119-seowon.dts target/linux/gemini/dts/

# 3. Registrar el nuevo dispositivo en el Makefile de Gemini
# Esto crea el perfil "seowon_swc9000" para que aparezca en el menú
echo "
define Device/seowon_swc9000
  DEVICE_VENDOR := Seowon
  DEVICE_MODEL := SWC9000
  DEVICE_DTS := mt7119-seowon
  SUPPORTED_DEVICES := seowon,swc9000
endef
TARGET_DEVICES += seowon_swc9000
" >> target/linux/gemini/image/Makefile

# 4. Inyectar tu configuración y forzar validación
cat ../seed.config > .config
make oldconfig
