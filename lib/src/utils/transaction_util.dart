import 'dart:async';
import 'dart:developer' as dev;
import 'package:archethic_lib_dart/archethic_lib_dart.dart';

mixin TransactionMixin {
  Future<void> sendTransactions(
    List<Transaction> transactions,
    ApiService apiService,
  ) async {
    var errorDetail = '';
    for (final transaction in transactions) {
      if (errorDetail.isNotEmpty) {
        break;
      }
      var next = false;
      String websocketEndpoint;
      switch (apiService.endpoint) {
        case 'https://mainnet.archethic.net':
        case 'https://testnet.archethic.net':
          websocketEndpoint =
              "${apiService.endpoint.replaceAll('https:', 'wss:').replaceAll('http:', 'wss:')}/socket/websocket";
          break;
        default:
          websocketEndpoint =
              "${apiService.endpoint.replaceAll('https:', 'wss:').replaceAll('http:', 'ws:')}/socket/websocket";
          break;
      }

      final transactionRepository = ArchethicTransactionSender(
        apiService: apiService,
        phoenixHttpEndpoint: '${apiService.endpoint}/socket/websocket',
        websocketEndpoint: websocketEndpoint,
      );
      await transactionRepository.send(
        transaction: transaction,
        onConfirmation: (confirmation) async {
          if (confirmation.isEnoughConfirmed) {
            dev.log(
              'nbConfirmations: ${confirmation.nbConfirmations}, transactionAddress: ${confirmation.transactionAddress}, maxConfirmations: ${confirmation.maxConfirmations}',
              name: 'TransactionDexMixin - sendTransactions',
            );

            transactionRepository.close();
            next = true;
          }
        },
        onError: (error) async {
          transactionRepository.close();
          error.maybeMap(
            connectivity: (_) {
              errorDetail = 'No connection';
            },
            consensusNotReached: (_) {
              errorDetail = 'Consensus not reached';
            },
            timeout: (_) {
              errorDetail = 'Timeout';
            },
            invalidConfirmation: (_) {
              errorDetail = 'Invalid Confirmation';
            },
            insufficientFunds: (_) {
              errorDetail = 'Insufficient funds';
            },
            other: (error) {
              errorDetail = error.messageLabel;
            },
            orElse: () {
              errorDetail = 'An error is occured';
            },
          );
        },
      );

      while (next == false && errorDetail.isEmpty) {
        await Future.delayed(const Duration(seconds: 1));
        dev.log('wait...');
      }
    }

    if (errorDetail.isNotEmpty) {
      throw Exception(errorDetail);
    }
  }
}
