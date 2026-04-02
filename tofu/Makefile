.PHONY: secrets-edit secrets-decode env-print

SECRETS_FILE := secrets.yaml
DECODED_FILE := .secrets.decoded.yaml

# Open secrets.yaml in your $EDITOR via sops
secrets-edit:
	sops $(SECRETS_FILE)

# Decode secrets.yaml into a local tmp file (gitignored)
secrets-decode:
	sops -d $(SECRETS_FILE) > $(DECODED_FILE)
	@echo "Decoded secrets written to $(DECODED_FILE)"

# Print export commands — eval in your shell: eval $(make env-print)
env-print:
	@echo export AWS_ACCESS_KEY_ID=$$(sops -d --extract '["backend"]["s3_access_key_id"]' $(SECRETS_FILE))
	@echo export AWS_SECRET_ACCESS_KEY=$$(sops -d --extract '["backend"]["s3_secret_access_key"]' $(SECRETS_FILE))
