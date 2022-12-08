import 'dart:async';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../Helper/ApiBaseHelper.dart';
import '../../Helper/AppBtn.dart';
import '../../Helper/Color.dart';
import '../../Helper/ContainerDesing.dart';
import '../../Helper/Session.dart';
import '../../Helper/String.dart';
import '../../Provider/privacyProvider.dart';
import '../TermFeed/policys.dart';
import 'VerifyOTP.dart';

class SendOtp extends StatefulWidget {
  String? title;

  SendOtp({Key? key, this.title}) : super(key: key);

  @override
  _SendOtpState createState() => _SendOtpState();
}

class _SendOtpState extends State<SendOtp> with TickerProviderStateMixin {
  bool visible = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final mobileController = TextEditingController();
  final ccodeController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String? mobile, id, countrycode, countryName, mobileno;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      getVerifyUser();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        setState(() {
          _isNetworkAvail = false;
        });
        await buttonController!.reverse();
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    buttonController!.dispose();
    super.dispose();
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: fontColor),
        ),
        backgroundColor: lightWhite,
        elevation: 1.0,
      ),
    );
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, "TRY_AGAIN_INT_LBL")!,
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(const Duration(seconds: 2)).then(
                (_) async {
                  _isNetworkAvail = await isNetworkAvailable();
                  if (_isNetworkAvail) {
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget),
                    );
                  } else {
                    await buttonController!.reverse();
                    setState(
                      () {},
                    );
                  }
                },
              );
            },
          )
        ]),
      ),
    );
  }

  Future<void> getVerifyUser() async {
    var data = {Mobile: mobile};
    apiBaseHelper.postAPICall(verifyUserApi, data).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        await buttonController!.reverse();
        if (widget.title == getTranslated(context, "SEND_OTP_TITLE")!) {
          if (!error) {
            setSnackbar(msg!);

            setPrefrence(Mobile, mobile!);
            setPrefrence(COUNTRY_CODE, countrycode!);
            Future.delayed(const Duration(seconds: 1)).then(
              (_) {
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => VerifyOtp(
                      mobileNumber: mobile!,
                      countryCode: countrycode,
                      title: getTranslated(context, "SEND_OTP_TITLE")!,
                    ),
                  ),
                );
              },
            );
          } else {
            setSnackbar(msg!);
          }
        }
        if (widget.title == getTranslated(context, "FORGOT_PASS_TITLE")!) {
          if (!error) {
            setPrefrence(Mobile, mobile!);
            setPrefrence(COUNTRY_CODE, countrycode!);

            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => VerifyOtp(
                  mobileNumber: mobile!,
                  countryCode: countrycode,
                  title: getTranslated(context, "FORGOT_PASS_TITLE")!,
                ),
              ),
            );
          } else {
            setSnackbar(msg!);
          }
        }
      },
      onError: (error) async {
        await buttonController!.reverse();
      },
    );
  }

  verifyCodeTxt() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 40.0,
        left: 40.0,
        right: 40.0,
        bottom: 20.0,
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          getTranslated(context, "SEND_VERIFY_CODE_LBL")!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.subtitle2!.copyWith(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
        ),
      ),
    );
  }

  setCodeWithMono() {
    return SizedBox(
      width: width * 0.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7.0),
          color: lightWhite,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: setCountryCode(),
            ),
            Expanded(
              flex: 4,
              child: setMono(),
            )
          ],
        ),
      ),
    );
  }

  setCountryCode() {
    return CountryCodePicker(
        showCountryOnly: false,
        flagWidth: 20,
        searchDecoration: InputDecoration(
          hintText: getTranslated(context, "COUNTRY_CODE_LBL")!,
          fillColor: fontColor,
        ),
        showOnlyCountryWhenClosed: false,
        initialSelection: 'IN',
        dialogSize: Size(width, height),
        alignLeft: true,
        textStyle: const TextStyle(
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (CountryCode countryCode) {
          countrycode = countryCode.toString().replaceFirst("+", "");
          countryName = countryCode.name;
        },
        onInit: (code) {
          countrycode = code.toString().replaceFirst("+", "");
        });
  }

  setMono() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: mobileController,
      style: Theme.of(context)
          .textTheme
          .subtitle2!
          .copyWith(color: fontColor, fontWeight: FontWeight.normal),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSaved: (String? value) {
        mobile = value;
      },
      // validator: (val) => validateMob(val!, context),
      decoration: InputDecoration(
        focusedBorder: UnderlineInputBorder(
          borderSide: const BorderSide(color: primary),
          borderRadius: BorderRadius.circular(7.0),
        ),
        hintText: getTranslated(context, "MOBILEHINT_LBL")!,
        hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
              color: fontColor,
              fontWeight: FontWeight.normal,
            ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: lightWhite,
          ),
        ),
      ),
    );
  }

  verifyBtn() {
    return AppBtn(
      title: widget.title == getTranslated(context, "SEND_OTP_TITLE")
          ? getTranslated(context, "Send OTP")!
          : getTranslated(context, "GET_PASSWORD")!,
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        validateAndSubmit();
      },
    );
  }

  termAndPolicyTxt() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            getTranslated(context, "CONTINUE_AGREE_LBL")!,
            style: Theme.of(context).textTheme.caption!.copyWith(
                  color: fontColor,
                  fontWeight: FontWeight.normal,
                ),
          ),
          const SizedBox(
            height: 3.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<SystemProvider>(
                        create: (context) => SystemProvider(),
                        child: Policy(
                          title: getTranslated(context, "TERM_CONDITIONS")!,
                              ),
                      ),
                    ),
                  );
                },
                child: Text(
                  getTranslated(context, "TERMS_SERVICE_LBL")!,
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: fontColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
              const SizedBox(
                width: 5.0,
              ),
              Text(
                getTranslated(context, "AND_LBL")!,
                style: Theme.of(context).textTheme.caption!.copyWith(
                      color: fontColor,
                      fontWeight: FontWeight.normal,
                    ),
              ),
              const SizedBox(
                width: 5.0,
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<SystemProvider>(
                        create: (context) => SystemProvider(),
                        child: Policy(
                          title: getTranslated(context, "PRIVACYPOLICY")!,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  getTranslated(context, "PRIVACY_POLICY_LBL")!,
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: fontColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.initState();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: width * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      body: _isNetworkAvail
          ? Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: back(),
                ),
                Image.asset(
                  'assets/images/doodle.png',
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: double.infinity,
                ),
                getLoginContainer(),
                getLogo(),
              ],
            )
          : noInternet(context),
    );
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      top: MediaQuery.of(context).size.height * 0.2,
      textDirection: Directionality.of(context),
      child: ClipPath(
        clipper: ContainerClipper(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.6),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.95,
          color: white,
          child: Form(
            key: _formkey,
            child: ScrollConfiguration(
              behavior: MyBehavior(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            getTranslated(context, "FORGOT_PASSWORDTITILE")!,
                            style: const TextStyle(
                              color: primary,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      verifyCodeTxt1(),
                      setCodeWithMono1(),
                      verifyBtn(),
                      termAndPolicyTxt(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget verifyCodeTxt1() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          getTranslated(context, "SEND_VERIFY_CODE_LBL")!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.subtitle2!.copyWith(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget setCodeWithMono1() {
    return SizedBox(
      width: width * 0.9,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: setCountryCode(),
          ),
          Expanded(
            flex: 4,
            child: setMono(),
          )
        ],
      ),
    );
  }

  Widget getLogo() {
    return Positioned(
      left: (MediaQuery.of(context).size.width / 2) - 50,
      top: (MediaQuery.of(context).size.height * 0.2) - 50,
      child: SizedBox(
        width: 100,
        height: 100,
        child: SvgPicture.asset(
          'assets/images/loginlogo.svg',
        ),
      ),
    );
  }
}
