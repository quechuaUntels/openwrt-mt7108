#!/bin/bash

DTS=target/linux/gemini/dts/gemini
RTP=files/etc/Wireless/RT2870AP
FMW=files/lib/firmware
NAM=gemini-mt7119-seowon.dts

# 1. Definir la ruta del repositorio de archivos (hw, configs, etc.)
RR="${GITHUB_WORKSPACE:-$(dirname "$PWD")}"

# 2. VALIDACIÓN DE ESTRUCTURA (Capa de Seguridad 1)
# En lugar de crearla, comprobamos si existe.
if [ ! -d "target/linux/gemini/image" ]; then
    echo "ERROR CRÍTICO: No se encuentra la ruta target/linux/gemini/image/"
    # Listamos el contenido para diagnóstico
    ls -R target/linux/gemini/ 2>/dev/null || echo "La carpeta gemini no existe."
    exit 1
fi

# 3. PREPARACIÓN DE RUTAS PARA FIRMWARE Y DTS
# Estas sí las creamos porque son para tus archivos personalizados
mkdir -p $DTS
mkdir -p $RTP
mkdir -p $FMW

# 4. INYECCIÓN DE ARCHIVOS FÍSICOS
if [ -f "$RR/hw/rt2870.bin" ]; then
    cp -f "$RR/hw/rt2870.bin" $RTP/
    cp -f "$RR/hw/rt2870.bin" $FMW/
fi
[ -f "$RR/hw/RT2870AP.dat" ] && cp -f "$RR/hw/RT2870AP.dat" $RTP/
[ -f "$RR/hw/mt7119-seowon.dts" ] && cp -f "$RR/hw/mt7119-seowon.dts" $DTS/$NAM
[ -f "$RR/hw/mt7108.dtsi" ] && cp -f "$RR/hw/mt7108.dtsi" $DTS/

# 5. INYECCIÓN DEL MAKEFILE (Usando tu fragmento con TABULADORES)
# Usamos el archivo externo para asegurar que los tabs se mantengan intactos
FRAG="$RR/hw/gemini.makefile"
MAKEFILE="target/linux/gemini/image/Makefile"

if [ -f "$FRAG" ] && [ -f "$MAKEFILE" ]; then
    if ! grep -q "seowon_swc9000" "$MAKEFILE"; then
        echo "Inyectando perfil seowon_swc9000 en $MAKEFILE..."
        # cat "$FRAG" >> "$MAKEFILE"
	# Busca la línea del eval y coloca el fragmento JUSTO ANTES
        sed -i "/\$(eval \$(call BuildImage))/i \#jfq" "$MAKEFILE"
        sed -i "/\#jfq/r $FRAG" "$MAKEFILE"

        echo "Inyección completada con éxito."
    else
        echo "El dispositivo ya existe en el Makefile."
    fi
else
    echo "ERROR: No se encontró el fragmento $FRAG"
    exit 1
fi

# 6. VERIFICACIÓN VISUAL (Para el log de GitHub)
echo "--- ÚLTIMAS 15 LÍNEAS DEL MAKEFILE MODIFICADO ---"
tail -n 15 "$MAKEFILE"
echo "-----------------------------------------------"

# 7. CARGA DE CONFIGURACIÓN Y VALIDACIÓN FINAL
if [ -f "$RR/seed.config" ]; then
    echo "Cargando seed.config..."
    cat "$RR/seed.config" > .config
    
    if ! grep -q "CONFIG_TARGET_gemini_generic_DEVICE_seowon_swc9000=y" .config; then
	echo "Forzando selección de hardware en .config..."
        echo "CONFIG_TARGET_gemini=y" >> .config
        echo "CONFIG_TARGET_gemini_generic=y" >> .config
        echo "CONFIG_TARGET_gemini_generic_DEVICE_seowon_swc9000=y" >> .config
    fi

    # Validamos con oldconfig (no interactivo)
    echo "Ejecutando make defconfig..."
    make defconfig
    
    # Comprobación de éxito: ¿Sigue seleccionado nuestro dispositivo?
    if grep -q "CONFIG_TARGET_gemini_generic_DEVICE_seowon_swc9000=y" .config; then
	    echo "ÉXITO: Dispositivo validado y dependencias resueltas por defconfig."
	    make target/linux/clean
		yes "" | make target/linux/compile
    else
        echo "ERROR: El dispositivo fue RECHAZADO por el sistema de configuración."
	    echo "Revisa que el fragmento Makefile tengyes "" | make target/linux/compilea los TABULADORES correctos."
        exit 1
    fi
else
    echo "ERROR: No se encontró seed.config en $RR"
    exit 1
fi
