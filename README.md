[![CI](https://github.com/archethic-foundation/messaging_dart_sdk/actions/workflows/ci.yaml/badge.svg)](https://github.com/archethic-foundation/messaging_dart_sdk/actions/workflows/ci.yaml) [![Pub](https://img.shields.io/pub/v/archethic_messaging_lib_dart.svg)](https://pub.dartlang.org/packages/archethic_messaging_lib_dart) [![Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)

# Archethic's Messaging Dart SDK

Archethic Messaging SDK developped on Dart

## Usage

This library aims to provide a easy way to manage a decentralized messaging platform on the Archethic Public Blockchain.
With the help of a smart contract, you can manage discussions and associated messages.

## API

All API are available in `messaging_service.dart` file.

### Installation

To use the `MessagingService` class, you should include the `archethic_lib_dart` and `archethic_messaging_lib_dart` packages in your Dart project. Add the following dependencies to your `pubspec.yaml` file:

```yaml

dependencies:
  archethic_lib_dart: ^<version>
  archethic_messaging_lib_dart: ^<version>

```

### Initialization
```dart

import 'package:archethic_lib_dart/archethic_lib_dart.dart' as archethic;
import 'package:archethic_messaging_lib_dart/archethic_messaging_lib_dart';

void main() {
  // Initialize your keychain and API service as needed.
  archethic.Keychain keychain = ...; // Initialize your keychain
  archethic.ApiService apiService = ...; // Initialize your API service

  // Create an instance of MessagingService
  MessagingService messagingService = MessagingService(
    logsActivation: true, // Set to true to enable logging
  );
}

```

### Discussion
#### Create a New Discussion
Creates a new discussion on the blockchain.

```dart
Future<({
  archethic.Transaction transaction,
  archethic.KeyPair previousKeyPair
})> createDiscussion({
  required archethic.Keychain keychain,
  required archethic.ApiService apiService,
  required List<String> membersPubKey,
  required String discussionName,
  required List<String> adminsPubKey,
  required String adminAddress,
  required String serviceName,
})
```

Parameters:
- `keychain`: Keychain used to send transactions to the blockchain.
- `apiService`: API service with blockchain integration.
- `membersPubKey`: List of public keys of all discussion members.
- `discussionName`: Name of the discussion.
- `adminsPubKey`: List of public keys of all discussion administrators.
- `adminAddress`: Address of the admin who wants to add members (provisions the SC's chain to manage fees).
- `serviceName`: Service name in the current keychain (admin).
- Returns a future with transaction and previous key pair information.

#### Update an Existing Discussion
Updates an existing discussion on the blockchain.

```dart
Future<({
  archethic.Transaction transaction,
  archethic.KeyPair previousKeyPair
})> updateDiscussion({
  required archethic.Keychain keychain,
  required archethic.ApiService apiService,
  required String discussionSCAddress,
  required List<String> membersPubKey,
  required String discussionName,
  required List<String> adminsPubKey,
  required String adminAddress,
  required String serviceName,
  required archethic.KeyPair adminKeyPair,
  bool updateSCAESKey = false,
})
```
Parameters:
- `keychain`: Keychain used to send transactions to the blockchain.
- `apiService`: API service with blockchain integration.
- `membersPubKey`: List of public keys of all discussion members.
- `discussionName`: Name of the discussion.
- `adminsPubKey`: List of public keys of all discussion administrators.
- `adminAddress`: Address of the admin who wants to add members (provisions the SC's chain to manage fees).
- `serviceName`: Service name in the current keychain (admin).
- Returns a future with transaction and previous key pair information.

#### Update an Existing Discussion
Updates an existing discussion on the blockchain.

```dart
Future<({
  archethic.Transaction transaction,
  archethic.KeyPair previousKeyPair
})> updateDiscussion({
  required archethic.Keychain keychain,
  required archethic.ApiService apiService,
  required String discussionSCAddress,
  required List<String> membersPubKey,
  required String discussionName,
  required List<String> adminsPubKey,
  required String adminAddress,
  required String serviceName,
  required archethic.KeyPair adminKeyPair,
  bool updateSCAESKey = false,
})
```
Parameters:
- `keychain`: Keychain used to send transactions to the blockchain.
- `apiService`: API service with blockchain integration.
- `discussionSCAddress`: Smart contract's address for the discussion.
- `membersPubKey`: List of public keys of all discussion members.
- `discussionName`: Name of the discussion.
- `adminsPubKey`: List of public keys of all discussion administrators.
- `adminAddress`: Address of the admin who wants to add members (provisions the SC's chain to manage fees).
- `serviceName`: Service name in the current keychain (admin).
- `adminKeyPair`: Key pair of the admin.
- `updateSCAESKey`: Update the AES key if set to true.
- Returns a future with transaction and previous key pair information.

#### Get a Discussion
Retrieves a discussion from its address on the blockchain.

```dart
Future<AEDiscussion?> getDiscussion({
  required archethic.ApiService apiService,
  required String discussionSCAddress,
  required archethic.KeyPair keyPair,
})
```

Parameters:
- `apiService`: API service with blockchain integration.
- `discussionSCAddress`: Smart contract's address for the discussion.
- `keyPair`: Key pair of the requester to check if the discussion's content can be decrypted.
- Returns an AEDiscussion object or null if not found.

#### Get the last properties of a discussion

```dart
Future<String> getDiscussionLastProperties({
    required archethic.ApiService apiService,
    required String discussionSCAddress,
    required archethic.KeyPair readerKeyPair,
  })
```

Parameters:
- `apiService`: API service with blockchain integration.
- `discussionSCAddress`: Smart contract's address for the discussion.
- `readerKeyPair`: Key pair of the reader to check if the discussion's content can be decrypted.
  
### Messages
#### Read Messages in Existing Discussion
Reads messages in an existing discussion on the blockchain.

```dart
Future<List<AEMessage>> readMessages({
  required archethic.ApiService apiService,
  required String discussionSCAddress,
  required archethic.KeyPair readerKeyPair,
  int limit = 0,
  int pagingOffset = 0,
})
```

Parameters:
- `apiService`: API service with blockchain integration.
- `discussionSCAddress`: Smart contract's address for the discussion.
- `readerKeyPair`: Key pair of the reader.
- `limit`: Limit the number of messages to retrieve (default is 0, which retrieves all).
- `pagingOffset`: Offset for paging through messages.
- Returns a list of AEMessage objects.

#### Send Messages in Existing Discussion
Sends a message in an existing discussion on the blockchain.

```dart
Future<({
  archethic.Address transactionAddress,
  archethic.KeyPair previousKeyPair
})> sendMessage({
  required archethic.Keychain keychain,
  required archethic.ApiService apiService,
  required String discussionSCAddress,
  required String messageContent,
  required String senderAddress,
  required String senderServiceName,
  required archethic.KeyPair senderKeyPair,
})
```
Parameters:
- `keychain`: Keychain used to send transactions to the blockchain.
- `apiService`: API service with blockchain integration.
- `discussionSCAddress`: Smart contract's address for the discussion.
- `messageContent`: Content of the message (not encrypted).
- `senderAddress`: Address of the member who wants to send the message.
- `senderServiceName`: Service name in the current keychain (sender).
- `senderKeyPair`: Key pair of the sender.
- Returns a future with transaction address and previous key pair information.

#### Build a message
```dart
  Future<({
        archethic.Transaction transaction,
        archethic.KeyPair previousKeyPair
      })> buildMessage({
    required archethic.Keychain keychain,
    required archethic.ApiService apiService,
    required String discussionSCAddress,
    required String messageContent,
    required String senderAddress,
    required String senderServiceName,
    required archethic.KeyPair senderKeyPair,
  })
  ```

Parameters:
- `keychain`: Keychain used to send transactions to the blockchain.
- `apiService`: API service with blockchain integration.
- `discussionSCAddress`: Smart contract's address for the discussion.
- `messageContent`: Content of the message (not encrypted).
- `senderAddress`: Address of the member who wants to send the message.
- `senderServiceName`: Service name in the current keychain (sender).
- `senderKeyPair`: Key pair of the sender.
- Returns a future with transaction address and previous key pair information.


## Running the tests

```bash
dart test --exclude-tags noCI
```