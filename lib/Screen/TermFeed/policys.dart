import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:sellermultivendor/Helper/String.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Helper/ApiBaseHelper.dart';
import '../../Helper/Session.dart';
import '../../Provider/privacyProvider.dart';

class Policy extends StatefulWidget {
  String? title;

  Policy({
    this.title,
  });
  @override
  _PolicyState createState() => _PolicyState();
}

class _PolicyState extends State<Policy> {
//==============================================================================
//============================= Variables Declaration ==========================

  bool _isNetworkAvail = true;
  String? contactUs;
  String? termCondition;
  String? privacyPolicy;
  String? returnPolicy;
  String? shippingPolicy;
  ApiBaseHelper apiBaseHelper = ApiBaseHelper();

//==============================================================================
//============================= initState Method ===============================

  @override
  void initState() {
    super.initState();
    getSystemPolicy();
  }

  Future<void> getSystemPolicy() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      String type = '';
      if (widget.title == getTranslated(context, 'PRIVACYPOLICY')) {
        type = "privacy_policy";
      } else if (widget.title == getTranslated(context, 'TERM_CONDITIONS')) {
        type = "terms_conditions";
      } else if (widget.title == getTranslated(context, 'CONTACTUS')) {
        type = "contact_us";
      } else if (widget.title == getTranslated(context, 'Shipping Policy')) {
        type = "shipping_policy";
      } else if (widget.title == getTranslated(context, 'Return Policy')) {
        type = "return_policy";
      }

      await Future.delayed(Duration.zero);
      await context.read<SystemProvider>().getSystemPolicies(type);
    }
  }
//==============================================================================
//============================= Build Method ===================================

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: getAppBar(
        widget.title!,
        context,
      ),
      body: _isNetworkAvail
          ? Consumer<SystemProvider>(
              builder: (context, value, child) {
                if (value.getCurrentStatus ==
                    SystemProviderPolicyStatus.isSuccsess) {
                  if (value.policy.isNotEmpty) {
                    print("value : ${value.policy} ");

                    return SingleChildScrollView(
                      child: HtmlWidget(
                        value.policy,
                        onErrorBuilder: (context, element, error) =>
                            Text('$element error: $error'),
                        onLoadingBuilder: (context, element, loadingProgress) =>
                            const CircularProgressIndicator(),

                        onTapUrl: (url) {
                          launchUrl(Uri.parse(url));
                          return true;
                        },

                        renderMode: RenderMode.column,

                        // set the default styling for text
                        textStyle: const TextStyle(fontSize: 14),

                        webView: true,
                      ),
                    );
                  } else {
                    const Center(
                      child: Text('No Data Found'),
                    );
                  }
                } else if (value.getCurrentStatus ==
                    SystemProviderPolicyStatus.isFailure) {
                  return Center(
                    child: Text('Something went wrong:- ${value.errorMessage}'),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            )
          : noInternet(context),
    );
  }
}

//==============================================================================
//============================ No Internet Widget ==============================

noInternet(BuildContext context) {
  return Center(
    child: Text(
      getTranslated(context, "NoInternetAwailable")!,
    ),
  );
}
