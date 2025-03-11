#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Configurations
EXPORT_DIR='/tmp'
LOG_FILE="${0}.log"
GPG_LOG_FILE="${EXPORT_DIR}/gpg_install.log"
ALICE="alice"
BOB="bob"
CAROL="carol"

# Debug mode flag (default: disabled)
DEBUG_MODE=false

# Function to log messages
log_message() {
    local LEVEL=$1
    local MESSAGE=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [${LEVEL}] - ${MESSAGE}" | tee -a "$LOG_FILE" > /dev/null
}

# Function to log errors
log_error() {
    log_message "ERROR" "$1"
}

# Function to log command output (only if debug mode is enabled)
log_command_output() {
    if $DEBUG_MODE; then
        local COMMAND_OUTPUT=$1
        while IFS= read -r line; do
            log_message "DEBUG" "$line"
        done <<< "$COMMAND_OUTPUT"
    fi
}

# Function to parse script arguments
parse_arguments() {
    while getopts ":d" opt; do
        case $opt in
            d)
                DEBUG_MODE=true
                log_message "INFO" "Debug mode enabled."
                ;;
            \?)
                log_error "Invalid option: -$OPTARG"
                exit 1
                ;;
        esac
    done
}

# Function to install GPG
install_gpg() {
    if ! command -v gpg &> /dev/null; then
        log_message "INFO" "GPG is not installed. Installing..."
        OUTPUT=$(sudo apt-get update && sudo apt-get install -y gnupg 2>&1)
        log_command_output "$OUTPUT"
        if [ $? -eq 0 ]; then
            log_message "INFO" "GPG installed successfully."
        else
            log_error "Failed to install GPG."
            return 1
        fi
    else
        log_message "INFO" "GPG is already installed."
    fi
}

# Function to create a user
create_user() {
    local USERNAME=$1
    if ! id "$USERNAME" &>/dev/null; then
        log_message "INFO" "Creating user $USERNAME..."
        OUTPUT=$(sudo adduser --disabled-password --gecos "" "$USERNAME" 2>&1)
        log_command_output "$OUTPUT"
        if [ $? -eq 0 ]; then
            log_message "INFO" "User $USERNAME created successfully."
        else
            log_error "Failed to create user $USERNAME."
            return 1
        fi
    else
        log_message "INFO" "User $USERNAME already exists."
    fi
}

# Function to set up GPG for a user
setup_gpg() {
    local USERNAME=$1
    local HOME_DIR=$(eval echo ~$USERNAME)
    log_message "INFO" "Setting up GPG for user $USERNAME..."
    OUTPUT=$(sudo rm -rf "$HOME_DIR/.gnupg" 2>&1)
    log_command_output "$OUTPUT"
    if [ $? -eq 0 ]; then
        log_message "INFO" ".gnupg directory removed for user $USERNAME."
    else
        log_error "Failed to remove .gnupg directory for user $USERNAME."
        return 1
    fi
}

# Function to generate a GPG key
generate_gpg_key() {
    local USERNAME=$1
    log_message "INFO" "Generating GPG key for user $USERNAME..."
    OUTPUT=$(sudo -u "$USERNAME" gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key "$USERNAME <${USERNAME}@example.com>" rsa2048 encr 2>&1)
    log_command_output "$OUTPUT"
    if [ $? -eq 0 ]; then
        log_message "INFO" "GPG key generated successfully for user $USERNAME."
    else
        log_error "Failed to generate GPG key for user $USERNAME."
        return 1
    fi
}

# Function to export a public key
export_public_key() {
    local USERNAME=$1
    local PUB_KEY_FILE="$EXPORT_DIR/${USERNAME}_public.gpg"
    log_message "INFO" "Exporting public key for user $USERNAME..."
    OUTPUT=$(sudo -u "$USERNAME" gpg --yes --output "$PUB_KEY_FILE" --export "$USERNAME" 2>&1)
    log_command_output "$OUTPUT"
    if [ $? -eq 0 ]; then
        log_message "INFO" "Public key exported successfully to $PUB_KEY_FILE."
        sudo chmod 644 "$PUB_KEY_FILE"
    else
        log_error "Failed to export public key for user $USERNAME."
        return 1
    fi
}

# Function to import a public key
import_public_key() {
    local TARGET_USER=$1
    local SOURCE_USER=$2
    local PUB_KEY_FILE="$EXPORT_DIR/${SOURCE_USER}_public.gpg"
    if [ ! -f "$PUB_KEY_FILE" ]; then
        log_error "Public key file $PUB_KEY_FILE not found."
        return 1
    fi
    log_message "INFO" "Importing public key of $SOURCE_USER for user $TARGET_USER..."
    OUTPUT=$(sudo -u "$TARGET_USER" gpg --yes --import "$PUB_KEY_FILE" 2>&1)
    log_command_output "$OUTPUT"
    if [ $? -eq 0 ]; then
        log_message "INFO" "Public key of $SOURCE_USER imported successfully for user $TARGET_USER."
        # Set trust level to ultimate for the imported key
        OUTPUT=$(echo -e "trust\n5\ny\nsave\n" | sudo -u "$TARGET_USER" gpg --command-fd 0 --edit-key "$SOURCE_USER" 2>&1)
        log_command_output "$OUTPUT"
        if [ $? -eq 0 ]; then
            log_message "INFO" "Key of $SOURCE_USER marked as trusted for user $TARGET_USER."
        else
            log_error "Failed to set trust for key of $SOURCE_USER."
            return 1
        fi
    else
        log_error "Failed to import public key of $SOURCE_USER."
        return 1
    fi
}

# Function to encrypt a message
encrypt_message() {
    local SENDER=$1
    local RECIPIENT=$2
    local MESSAGE_FILE="/tmp/shared_message.txt"
    local ENCRYPTED_FILE="${MESSAGE_FILE}.gpg"
    echo "Secret message from $SENDER to $RECIPIENT" | sudo tee "$MESSAGE_FILE" > /dev/null
    sudo chmod 777 "$MESSAGE_FILE"
    log_message "INFO" "$SENDER is encrypting $MESSAGE_FILE for $RECIPIENT..."
    OUTPUT=$(sudo -u "$SENDER" gpg --yes --encrypt --recipient "$RECIPIENT" --output "$ENCRYPTED_FILE" "$MESSAGE_FILE" 2>&1)
    log_command_output "$OUTPUT"
    if [ $? -eq 0 ]; then
        log_message "INFO" "$SENDER successfully encrypted a message for $RECIPIENT."
    else
        log_error "Failed to encrypt message from $SENDER for $RECIPIENT."
        return 1
    fi
}

# Function to decrypt a message
decrypt_message() {
    local RECIPIENT=$1
    local FROM=$2
    local ENCRYPTED_FILE="/tmp/shared_message.txt.gpg"
    local DECRYPTED_FILE="${ENCRYPTED_FILE%.gpg}.dec"
    if [ ! -f "$ENCRYPTED_FILE" ]; then
        log_error "Encrypted file $ENCRYPTED_FILE not found! Cannot decrypt."
        return 1
    fi
    log_message "INFO" "$RECIPIENT is attempting to decrypt the message from ${FROM}..."
    OUTPUT=$(sudo -u "$RECIPIENT" gpg --batch --yes --pinentry-mode loopback --decrypt --output "$DECRYPTED_FILE" "$ENCRYPTED_FILE" 2>&1)
    log_command_output "$OUTPUT"
    if [ -f "$DECRYPTED_FILE" ]; then
        local msg=$(sudo cat "$DECRYPTED_FILE")
        sudo rm -rf "$DECRYPTED_FILE"
        sudo rm -rf "$ENCRYPTED_FILE"
        log_message "INFO" "Message from ${FROM} successfully decrypted by $RECIPIENT: ${msg}"
    else
        log_error "$RECIPIENT failed to decrypt the message from ${FROM}."
        return 1
    fi
}

# Function to kill the GPG agent
kill_gpg_agent() {
    log_message "INFO" "Killing gpg-agent process..."
    OUTPUT=$(sudo pkill gpg-agent 2>&1)
    log_command_output "$OUTPUT"
    if [ $? -eq 0 ]; then
        log_message "INFO" "gpg-agent killed successfully."
    else
        log_error "Failed to kill gpg-agent."
        return 1
    fi
}

# Function to clean up the environment
cleanup() {
    log_message "INFO" "Cleaning up temporary files and users..."
    kill_gpg_agent
    OUTPUT=$(sudo rm -f /tmp/message_* /tmp/*.gpg /tmp/*.dec 2>&1)
    log_command_output "$OUTPUT"
    for USERNAME in "$ALICE" "$BOB" "$CAROL"; do
        OUTPUT=$(sudo deluser --remove-home "$USERNAME" 2>&1)
        log_command_output "$OUTPUT"
        if [ $? -eq 0 ]; then
            log_message "INFO" "User $USERNAME removed successfully."
        else
            log_error "Failed to remove user $USERNAME."
        fi
    done
}

# Function to initialize the log file
init_task() {
    rm -rf "$LOG_FILE"
    touch "$LOG_FILE"
    log_message "INFO" "Log file is ready."
}

# Parse script arguments
parse_arguments "$@"

# Initialization
init_task

# Install GPG
install_gpg

# Create and configure users
for USERNAME in "$ALICE" "$BOB" "$CAROL"; do
    create_user "$USERNAME" || continue
    setup_gpg "$USERNAME" || continue
    generate_gpg_key "$USERNAME" || continue
    export_public_key "$USERNAME" || continue
done

# Import public keys
for USERNAME in "$ALICE" "$BOB" "$CAROL"; do
    for TARGET_USER in "$ALICE" "$BOB" "$CAROL"; do
        if [ "$USERNAME" != "$TARGET_USER" ]; then
            import_public_key "$TARGET_USER" "$USERNAME" || continue
        fi
    done
done

# Bob encrypts a message for Alice (then Carol tries to decrypt it)
encrypt_message "$BOB" "$ALICE" || log_error "Encryption from Bob to Alice failed."
decrypt_message "$CAROL" "$BOB" || log_error "Decryption by Carol failed (expected)."
decrypt_message "$ALICE" "$BOB" || log_error "Decryption by Alice failed."

# Alice encrypts a message for Bob (then Carol tries to decrypt it)
encrypt_message "$ALICE" "$BOB" || log_error "Encryption from Alice to Bob failed."
decrypt_message "$CAROL" "$BOB" || log_error "Decryption by Carol failed (expected)."
decrypt_message "$BOB" "$ALICE" || log_error "Decryption by Bob failed."

# Carol encrypts a message for Bob (then Alice tries to decrypt it)
encrypt_message "$CAROL" "$BOB" || log_error "Encryption from Carol to Bob failed."
decrypt_message "$ALICE" "$BOB" || log_error "Decryption by Alice failed (expected)."
decrypt_message "$BOB" "$CAROL" || log_error "Decryption by Bob failed."

# Final cleanup
cleanup

log_message "INFO" "Script completed."
