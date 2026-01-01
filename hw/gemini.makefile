define Device/seowon_swc9000
	$(Device/storlink-reference)
	DEVICE_VENDOR := Seowon
	DEVICE_MODEL := SWC9000
	DEVICE_DTS := gemini-mt7119-seowon
	SUPPORTED_DEVICES := seowon,swc9000
endef
