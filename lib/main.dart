import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel("razorpay_flutter");

  late Razorpay _razorpay;

  var amountTextEditingController = TextEditingController();
  var userContactTextEditingController = TextEditingController();
  var userEmailTextEditingController = TextEditingController();

  static const key_id = 'rzp_test_kyYpWmkyEILXhn';//Test
  static const key_secret = 'xGV81J8XU80cZQ94X8CL7wwd';//Test


  static const userId = 'userId_1234';
  static const id = 'orderId_5678'; //orderId
  static const description = 'AAR Payments';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: const Text('Razorpay Payment Test App'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: amountTextEditingController,
                  decoration: const InputDecoration(hintText: "Enter Amount"),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: userContactTextEditingController,
                  decoration:
                      const InputDecoration(hintText: "Enter Your Contact"),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: userEmailTextEditingController,
                  decoration:
                      const InputDecoration(hintText: "Enter Your Email"),
                ),
                const SizedBox(
                  height: 12,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.black),
                  child: const Text(
                    "Make Payment",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    createOrderId(description, id, userId);
                  },
                )
              ],
            ),
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void createOrderId(description, id, userId) async {
    final int amount = int.parse(amountTextEditingController.text) * 100;
    var response = await http.post(
        Uri.parse(
          "https://api.razorpay.com/v1/orders",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              'Basic ' + base64Encode(utf8.encode('$key_id:$key_secret'))
        },
        body: json.encode({
          "amount": amount,
          "currency": "INR",
          "receipt": "OrderId_$id",
          "notes": {
            "userId": "$userId",
            "packageId": "$id",
            "description": "$description"
          },
        }));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      openCheckout(amount, description, data["id"]);
    }
    print(response.body);
  }

  void openCheckout(amount, description, String orderId) async {
    var options = {
      'key': key_id,
      'amount': amount,
      'name': 'Business Name',
      'order_id': orderId, // Generate order_id using Orders API
      'description': description,
      'retry': {'enabled': true, 'max_count': 2},
      'send_sms_hash': true,
      'prefill': {
        'contact': userContactTextEditingController.text,
        'email': userEmailTextEditingController.text
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Success Response: $response');
    Fluttertoast.showToast(
        msg: "Payment Successful for id: ${response.paymentId!}",
        toastLength: Toast.LENGTH_SHORT);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    String msg = response.message.toString();
    print('Error Response: $msg');
    Fluttertoast.showToast(
        msg: "ERROR: ${response.code} - ${response.message!}",
        toastLength: Toast.LENGTH_SHORT);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External SDK Response: $response');
    Fluttertoast.showToast(
        msg: "EXTERNAL_WALLET: ${response.walletName!}",
        toastLength: Toast.LENGTH_SHORT);
  }
}
