.PHONY: antivirus restore pre-build

antivirus: pre-build
	./antivirusd.sh $(SCAN_DIR) $(MALICIOUS_DIR) $(INTERVAL_SEC)

restore: pre-build
	./restore.sh $(SCAN_DIR) $(MALICIOUS_DIR)

pre-build:
	mkdir -p $(MALICIOUS_DIR)
