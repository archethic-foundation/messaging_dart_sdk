/// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:archethic_lib_dart/archethic_lib_dart.dart';
import 'package:archethic_messaging_lib_dart/src/model/messaging/ae_message.dart';
import 'package:archethic_messaging_lib_dart/src/model/messaging/transaction_content_messaging.dart';
import 'package:archethic_messaging_lib_dart/src/utils/messenger/discussion_util.dart';
import 'package:archive/archive_io.dart';

/// For group discussions, a dedicated transaction chain will contain a smart contract and its updates, as well as the discussion's rules and description.
/// The messages will be contained in the inputs of the smart contracts in the chain.
/// A general public key for accessing messages is made available.
mixin MessagesMixin {
  Future<({Transaction transaction, KeyPair previousKeyPair})>
      buildMessageSendTransaction({
    required Keychain keychain,
    required ApiService apiService,
    required String discussionSCAddress,
    required String messageContent,
    required String senderAddress,
    required String senderServiceName,
    required KeyPair senderKeyPair,
  }) async {
    final message = '''
      {
        "compressionAlgo": "gzip",
        "message": "${await _encodeMessage(message: messageContent, apiService: apiService, discussionSCAddress: discussionSCAddress, senderKeyPair: senderKeyPair)}"
      }
    ''';

    final tx = Transaction(type: 'transfer', data: Transaction.initData())
        .setContent(message)
        .addRecipient(discussionSCAddress);

    final indexMap = await apiService.getTransactionIndex(
      [senderAddress],
    );

    final index = indexMap[senderAddress] ?? 0;
    final originPrivateKey = apiService.getOriginKey();

    final buildTxResult =
        keychain.buildTransaction(tx, senderServiceName, index);

    return (
      transaction: buildTxResult.transaction.originSign(originPrivateKey),
      previousKeyPair: buildTxResult.keyPair,
    );
  }

  Future<({Address transactionAddress, KeyPair previousKeyPair})> send({
    required Keychain keychain,
    required ApiService apiService,
    required String discussionSCAddress,
    required String messageContent,
    required String senderAddress,
    required String senderServiceName,
    required KeyPair senderKeyPair,
  }) async {
    final result = await buildMessageSendTransaction(
      keychain: keychain,
      apiService: apiService,
      discussionSCAddress: discussionSCAddress,
      messageContent: messageContent,
      senderAddress: senderAddress,
      senderServiceName: senderServiceName,
      senderKeyPair: senderKeyPair,
    );

    final transaction = result.transaction;
    await TransactionUtil().sendTransactions(
      transactions: [transaction],
      apiService: apiService,
    );
    return (
      transactionAddress: transaction.address!,
      previousKeyPair: result.previousKeyPair,
    );
  }

  /// This method encrypt a message with the AES Key ()
  Future<String> _encodeMessage({
    required String message,
    required ApiService apiService,
    required String discussionSCAddress,
    required KeyPair senderKeyPair,
  }) async {
    final discussionKeyAccess = await DiscussionUtil().getDiscussionKeyAccess(
      apiService: apiService,
      discussionSCAddress: discussionSCAddress,
      keyPair: senderKeyPair,
    );

    // Encode message with message key
    final stringPayload = utf8.encode(message);
    final compressedPayload = GZipEncoder().encode(stringPayload);
    final cryptedPayload = aesEncrypt(compressedPayload, discussionKeyAccess);
    return base64.encode(cryptedPayload);
  }

  Uint8List _decodeMessage(
    String compressedData,
    String discussionKeyAccess, {
    String compressionAlgo = '',
  }) {
    final payload = base64.decode(compressedData);
    final decryptedPayload = aesDecrypt(
      payload,
      discussionKeyAccess,
    );
    late List<int> decompressedPayload;
    switch (compressionAlgo) {
      case 'gzip':
        decompressedPayload = GZipDecoder().decodeBytes(decryptedPayload);
        break;
      default:
        decompressedPayload = decryptedPayload;
    }

    return Uint8List.fromList(decompressedPayload);
  }

  Future<List<AEMessage>> read({
    required ApiService apiService,
    required String discussionSCAddress,
    required KeyPair readerKeyPair,
    int limit = 0,
    int pagingOffset = 0,
  }) async {
    final transactions = await _listTransactions(
      apiService: apiService,
      discussionSCAddress: discussionSCAddress,
    );

    final txContentMessageAddressesToTransactionAddress =
        await _txContentMessageAddressesToTransactionAddress(
      apiService: apiService,
      transactions: transactions,
      limit: limit,
      pagingOffset: pagingOffset,
    );

    final aeMessages = <AEMessage>[];
    final contents = await apiService.getTransaction(
      txContentMessageAddressesToTransactionAddress.keys.toList(),
      request:
          ' address, chainLength, data { content }, previousPublicKey, validationStamp { timestamp } ',
    );

    if (contents.isEmpty) return [];

    for (final contentMessageAddress
        in txContentMessageAddressesToTransactionAddress.keys.toList()) {
      final discussionKeyAccess = uint8ListToHex(
        await DiscussionUtil().getDiscussionKeyAccess(
          apiService: apiService,
          discussionSCAddress: txContentMessageAddressesToTransactionAddress[
              contentMessageAddress]!,
          keyPair: readerKeyPair,
        ),
      );

      final contentMessageTransaction = contents[contentMessageAddress];
      if (contentMessageTransaction?.data?.content == null ||
          contentMessageTransaction!.data!.content!.isEmpty) {
        continue;
      }

      final transactionContentIM = TransactionContentMessaging.fromJson(
        jsonDecode(contentMessageTransaction.data!.content!),
      );
      final message = utf8.decode(
        _decodeMessage(
          transactionContentIM.message,
          discussionKeyAccess,
          compressionAlgo: transactionContentIM.compressionAlgo,
        ),
      );

      final senderGenesisPublicKeyMap = await apiService.getTransactionChain(
        {contentMessageTransaction.address!.address!: ''},
        request: 'previousPublicKey',
      );
      var senderGenesisPublicKey = '';
      if (senderGenesisPublicKeyMap.isNotEmpty &&
          senderGenesisPublicKeyMap[
                  contentMessageTransaction.address!.address!] !=
              null &&
          senderGenesisPublicKeyMap[
                  contentMessageTransaction.address!.address!]!
              .isNotEmpty) {
        senderGenesisPublicKey = senderGenesisPublicKeyMap[
                    contentMessageTransaction.address!.address!]?[0]
                .previousPublicKey ??
            '';
      }

      final aeMEssage = AEMessage(
        senderGenesisPublicKey: senderGenesisPublicKey,
        address: contentMessageTransaction.address!.address!,
        sender: contentMessageTransaction.previousPublicKey!,
        timestampCreation:
            contentMessageTransaction.validationStamp!.timestamp!,
        content: message,
      );

      aeMessages.add(
        aeMEssage,
      );
    }

    return aeMessages;
  }

  Future<List<Transaction>> _listTransactions({
    required ApiService apiService,
    required String discussionSCAddress,
  }) async {
    final listTransactions = <Transaction>[];

    final transactionChain = await apiService.getTransactionChain(
      {discussionSCAddress: ''},
      orderAsc: false,
    );

    if (transactionChain[discussionSCAddress] != null) {
      listTransactions.addAll(transactionChain[discussionSCAddress]!.toList());
    }

    return listTransactions;
  }

  Future<Map<String, String>> _txContentMessageAddressesToTransactionAddress({
    required ApiService apiService,
    required List<Transaction> transactions,
    int limit = 0,
    int pagingOffset = 0,
  }) async {
    final txContentMessageAddressesToTransactionAddress = <String, String>{};
    for (final transaction in transactions) {
      final transactionAddress = transaction.address?.address;

      if (transactionAddress == null) {
        continue;
      }

      var bufPagingOffset = pagingOffset;
      var bufTxContentMessageAddresses = <String>[];
      do {
        bufTxContentMessageAddresses = await _messagesAddresses(
          apiService: apiService,
          discussionSCAddress: transactionAddress,
          limit: limit,
          pagingOffset: bufPagingOffset,
        );

        for (final txContentMessageAddress in bufTxContentMessageAddresses) {
          txContentMessageAddressesToTransactionAddress[
              txContentMessageAddress] = transactionAddress;
        }
        bufPagingOffset += limit;
      } while (txContentMessageAddressesToTransactionAddress.length < limit &&
          bufTxContentMessageAddresses.isNotEmpty);

      if (txContentMessageAddressesToTransactionAddress.length >= limit) {
        break;
      }
    }
    return txContentMessageAddressesToTransactionAddress;
  }

  Future<List<String>> _messagesAddresses({
    required ApiService apiService,
    required String discussionSCAddress,
    int limit = 0,
    int pagingOffset = 0,
  }) async {
    final messagesList = await apiService.getTransactionInputs(
      [discussionSCAddress],
      limit: limit,
      pagingOffset: pagingOffset,
    );

    final txContentMessagesList =
        messagesList[discussionSCAddress] ?? <TransactionInput>[];
    final messageTransactions = txContentMessagesList
        .where(
          (txContentMessage) =>
              txContentMessage.from != null && txContentMessage.type == 'call',
        )
        .map((txContentMessage) => txContentMessage.from)
        .whereType<String>()
        .toList();
    final contents = await apiService.getTransaction(
      messageTransactions,
      request:
          ' address, chainLength, data { content }, previousPublicKey, validationStamp { timestamp } ',
    );

    return messageTransactions;
  }
}

class DiscussionUtil with DiscussionMixin {}
