.PHONY: secrets-edit secrets-decode env-print encrypt-file

SECRETS_FILE := secrets.yaml
DECODED_FILE := .secrets.decoded.yaml

# Open secrets.yaml in your $EDITOR via sops
secrets-edit:
	sops $(SECRETS_FILE)

# Decode secrets.yaml into a local tmp file (gitignored)
secrets-decode:
	sops -d $(SECRETS_FILE) > $(DECODED_FILE)
	@echo "Decoded secrets written to $(DECODED_FILE)"

# Encrypt a file in-place using sops + age: make encrypt-file FILE=path/to/file.yaml
# Relies on .sops.yaml config or SOPS_AGE_RECIPIENTS env var for the age recipient
encrypt-file:
	@test -n "$(FILE)" || (echo "Usage: make encrypt-file FILE=<path>"; exit 1)
	sops --encrypt --in-place $(FILE)

# Print export commands — eval in your shell: eval $(make env-print)
env-print:
	@echo export AWS_ACCESS_KEY_ID=$$(sops -d --extract '["backend"]["s3_access_key_id"]' $(SECRETS_FILE))
	@echo export AWS_SECRET_ACCESS_KEY=$$(sops -d --extract '["backend"]["s3_secret_access_key"]' $(SECRETS_FILE))
