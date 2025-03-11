# GPG Playground Script

The **GPG Playground Script** is a Bash script that demonstrates the use of GPG (GNU Privacy Guard) for key generation, encryption, and decryption. The script creates three users (Alice, Bob, and Carol), generates GPG keys for each of them, and simulates encrypted message exchange between them.

## Features

- **User creation**: Automatically creates users Alice, Bob, and Carol.
- **GPG key generation**: Generates GPG keys for each user.
- **Public key export/import**: Exports public keys and imports them into other users' keyrings.
- **Encryption and decryption**: Simulates encrypted message exchange between users.
- **Automatic cleanup**: Removes users and temporary files after execution.
- **Debug mode**: Supports a debug mode for detailed output.
- **Error handling**: Continues execution even if errors occur, logging all issues.

## Requirements

- **Bash**: The script is written in Bash and is compatible with most Unix-like shells.
- **GPG**: GPG must be installed on the system.
- **Root permissions**: The script requires root permissions to create users and manage system files.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/manzolo/gpg-bash-playground.git
   cd gpg-bash-playground
    ```

2. Make the script executable:
    ```bash
    chmod +x gpg_playground.sh
    ```

3. Run the script:
    ```bash
    sudo ./gpg_playground.sh
    ```

## Example Output

```
2025-03-11 20:32:24 - [INFO] - Log file is ready.
2025-03-11 20:32:24 - [INFO] - GPG is already installed.
2025-03-11 20:32:24 - [INFO] - Creating user alice...
2025-03-11 20:32:24 - [INFO] - User alice created successfully.
2025-03-11 20:32:26 - [INFO] - Public key exported successfully to /tmp/carol_public.gpg.
2025-03-11 20:32:26 - [INFO] - Importing public key of alice for user bob...
2025-03-11 20:32:26 - [INFO] - Public key of alice imported successfully for user bob.
...
2025-03-11 20:32:26 - [INFO] - carol is attempting to decrypt the message from bob...
2025-03-11 20:32:26 - [ERROR] - carol failed to decrypt the message from bob.
2025-03-11 20:32:26 - [ERROR] - Decryption by Carol failed (expected).
2025-03-11 20:32:26 - [INFO] - alice is attempting to decrypt the message from bob...
2025-03-11 20:32:26 - [INFO] - Message from bob successfully decrypted by alice: Secret message from bob to alice
2025-03-11 20:32:26 - [INFO] - alice is encrypting /tmp/shared_message.txt for bob...
2025-03-11 20:32:26 - [INFO] - alice successfully encrypted a message for bob.
2025-03-11 20:32:26 - [INFO] - carol is attempting to decrypt the message from bob...
2025-03-11 20:32:26 - [ERROR] - carol failed to decrypt the message from bob.
2025-03-11 20:32:26 - [ERROR] - Decryption by Carol failed (expected).
2025-03-11 20:32:26 - [INFO] - bob is attempting to decrypt the message from alice...
2025-03-11 20:32:26 - [INFO] - Message from alice successfully decrypted by bob: Secret message from alice to bob
2025-03-11 20:32:26 - [INFO] - carol is encrypting /tmp/shared_message.txt for bob...
2025-03-11 20:32:26 - [INFO] - carol successfully encrypted a message for bob.
2025-03-11 20:32:26 - [INFO] - alice is attempting to decrypt the message from bob...
2025-03-11 20:32:26 - [ERROR] - alice failed to decrypt the message from bob.
2025-03-11 20:32:26 - [ERROR] - Decryption by Alice failed (expected).
2025-03-11 20:32:26 - [INFO] - bob is attempting to decrypt the message from carol...
2025-03-11 20:32:26 - [INFO] - Message from carol successfully decrypted by bob: Secret message from carol to bob
2025-03-11 20:32:26 - [INFO] - Cleaning up temporary files and users...
2025-03-11 20:32:26 - [INFO] - Killing gpg-agent process...
2025-03-11 20:32:26 - [INFO] - gpg-agent killed successfully.
2025-03-11 20:32:26 - [INFO] - User alice removed successfully.
2025-03-11 20:32:26 - [INFO] - User bob removed successfully.
2025-03-11 20:32:26 - [INFO] - User carol removed successfully.
2025-03-11 20:32:26 - [INFO] - Script completed.

```