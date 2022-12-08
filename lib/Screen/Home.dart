import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:sellermultivendor/Helper/ApiBaseHelper.dart';
import 'package:sellermultivendor/Helper/AppBtn.dart';
import 'package:sellermultivendor/Helper/Color.dart';
import 'package:sellermultivendor/Helper/Constant.dart';
import 'package:sellermultivendor/Helper/String.dart';
import 'package:sellermultivendor/Localization/Language_Constant.dart';
import 'package:sellermultivendor/Screen/Add_Product.dart';
import 'package:sellermultivendor/Screen/Authentication/Login.dart';
import 'package:sellermultivendor/Screen/Customers.dart';
import 'package:sellermultivendor/Screen/OrderList.dart';
import 'package:sellermultivendor/Screen/ProductList.dart';
import 'package:sellermultivendor/Screen/SalesReport.dart';
import 'package:sellermultivendor/Screen/TermFeed/policys.dart';
import 'package:sellermultivendor/Screen/WalletHistory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helper/Indicator.dart';
import '../Helper/PushNotificationService.dart';
import '../Helper/Session.dart';
import '../Model/OrdersModel/OrderModel.dart';
import '../Provider/homeProvider.dart';
import '../Provider/privacyProvider.dart';
import '../Provider/walletProvider.dart';
import '../main.dart';
import 'Profile.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

bool _isLoading = true;
bool isLoadingmore = true;
String? delPermission;
ApiBaseHelper apiBaseHelper = ApiBaseHelper();
bool customerViewPermission = false;
Map<int, LineChartData>? chartList;
List colorList = [];

class _HomeState extends State<Home> with TickerProviderStateMixin {
//==============================================================================
//============================= Variables Declaration ==========================
  int curDrwSel = 0;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String?> languageList = [];
  List<Order_Model> tempList = [];
  int currentIndex = 0;
  String? errorTrueMessage;
  FocusNode? passFocus = FocusNode();
  final passwordController = TextEditingController();
  String? verifyPassword;
  String? all,
      received,
      processed,
      shipped,
      delivered,
      cancelled,
      returned,
      awaiting;
  String? mobile;
  final String _searchText = "";

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  ScrollController? controller;
  int? selectLan;
  bool _isNetworkAvail = true;
  String? activeStatus;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<String> statusList = [
    ALL,
    PLACED,
    PROCESSED,
    SHIPED,
    DELIVERD,
    CANCLED,
    RETURNED,
    awaitingPayment
  ];

//==============================================================================
//===================================== For Chart ==============================

  int curChart = 0;
  int? touchedIndex;

//==============================================================================
//============================= For Language Selection =========================

  List<String> langCode = [
    ENGLISH,
    HINDI,
    CHINESE,
    SPANISH,
    ARABIC,
    RUSSIAN,
    JAPANESE,
    DEUTSCH
  ];

  get lightWhite => null;

//==============================================================================
//============================= initState Method ===============================

  @override
  void initState() {
    callApi();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    final pushNotificationService = PushNotificationService(context: context);
    pushNotificationService.initialise();

    providerRequiestForData();
    getSallerDetail();

    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

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
    controller = ScrollController(keepScrollOffset: true);
    Future.delayed(
      Duration.zero,
      () {
        languageList = [
          getTranslated(context, 'English'),
          getTranslated(context, 'Hindi'),
          getTranslated(context, 'Chinese'),
          getTranslated(context, 'Spanish'),
          getTranslated(context, 'Arabic'),
          getTranslated(context, 'Russian'),
          getTranslated(context, 'Japanese'),
          getTranslated(context, 'Deutch'),
        ];
      },
    );
    super.initState();
  }

//==============================================================================
//============================= For Animation ==================================

//==============================================================================
//============================= For Animation ==================================

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

//==============================================================================
//============================= Build Method ===================================

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: lightWhite,
        appBar: getAppBar(context),
        drawer: getDrawer(context),
        body: getBodyPart(),
        floatingActionButton: floatingBtn(),
      ),
    );
  }

//==============================================================================
//=============================== floating Button ==============================

  floatingBtn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          backgroundColor: white,
          child: const Icon(
            Icons.add,
            size: 32,
            color: primary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute<String>(
                builder: (context) => const AddProduct(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

//==============================================================================
//============================ Headers Implimentation ==========================

  firstHeader(HomeProvider value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        commanDesingButtons(
          3,
          0,
          Icons.shopping_cart,
          getTranslated(context, "ORDER")!,
          value.totalorderCount,
        ),
        commanDesingButtons(
          4,
          1,
          Icons.account_balance_wallet,
          getTranslated(context, "BALANCE_LBL")!,
          getPriceFormat(context, double.parse(CUR_BALANCE))!,
        ),
        commanDesingButtons(
          3,
          2,
          Icons.wallet_giftcard,
          getTranslated(context, "PRODUCT_LBL")!,
          value.totalproductCount,
        ),
      ],
    );
  }

  secondHeader(HomeProvider value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // commanDesingButtons(1, 3, Icons.group,
        //     getTranslated(context, "CUSTOMER_LBL")!, totalcustCount),
        commanDesingButtons(1, 4, Icons.star_rounded, "Rating",
            RATTING + r" / " + NO_OFF_RATTING),
        commanDesingButtons(
            1, 7, Icons.star_rounded, "Report", value.grandFinalTotalOfSales),
      ],
    );
  }

  thirdHeader(HomeProvider value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        commanDesingButtons(
            2,
            5,
            Icons.not_interested,
            getTranslated(context, "Sold Out Products")!,
            value.totalsoldOutCount),
        commanDesingButtons(
            2,
            6,
            Icons.offline_bolt,
            getTranslated(context, "Low Stock Products")!,
            value.totallowStockCount),
      ],
    );
  }

//==============================================================================
//============================ Desing Implimentation ===========================

  commanDesingButtons(
    int flex,
    int index,
    IconData icon,
    String title,
    String? data,
  ) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          if (index == 0) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => OrderList(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) =>
                    ChangeNotifierProvider<WalletTransactionProvider>(
                  create: (context) => WalletTransactionProvider(),
                  child: const WalletHistory(),
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProductList(
                  flag: '',
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const Customers(),
              ),
            );
          } else if (index == 4) {
            //rating
          } else if (index == 5) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProductList(
                  flag: "sold",
                ),
              ),
            );
          } else if (index == 6) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProductList(
                  flag: "low",
                ),
              ),
            );
          } else if (index == 7) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const SalesReport(),
              ),
            );
          }
        },
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: primary,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data ?? "",
                  style: const TextStyle(
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

//==============================================================================
//=============================== chart coding  ================================

  getChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        height: 250,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.only(top: 10, left: 5, right: 15),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8),
                  child: Text(
                    getTranslated(context, "ProductSales")!,
                    style: Theme.of(context)
                        .textTheme
                        .headline6!
                        .copyWith(color: primary),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: curChart == 0
                        ? TextButton.styleFrom(
                            primary: Colors.white,
                            backgroundColor: primary,
                            onSurface: Colors.grey,
                          )
                        : null,
                    onPressed: () {
                      setState(
                        () {
                          curChart = 0;
                        },
                      );
                    },
                    child: Text(
                      getTranslated(context, "Day")!,
                    ),
                  ),
                  TextButton(
                    style: curChart == 1
                        ? TextButton.styleFrom(
                            primary: Colors.white,
                            backgroundColor: primary,
                            onSurface: Colors.grey,
                          )
                        : null,
                    onPressed: () {
                      setState(
                        () {
                          curChart = 1;
                        },
                      );
                    },
                    child: Text(
                      getTranslated(context, "Week")!,
                    ),
                  ),
                  TextButton(
                    style: curChart == 2
                        ? TextButton.styleFrom(
                            primary: Colors.white,
                            backgroundColor: primary,
                            onSurface: Colors.grey,
                          )
                        : null,
                    onPressed: () {
                      setState(
                        () {
                          curChart = 2;
                        },
                      );
                    },
                    child: Text(
                      getTranslated(context, "Month")!,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: LineChart(
                  chartList![curChart]!,
                  swapAnimationDuration: const Duration(milliseconds: 250),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

//1. LineChartData

  LineChartData dayData(HomeProvider value) {
    if (value.dayEarning!.isEmpty) {
      value.dayEarning!.add(0);
      value.days!.add(0);
    }
    List<FlSpot> spots = value.dayEarning!.asMap().entries.map(
      (e) {
        return FlSpot(
          double.parse(
            value.days![e.key].toString(),
          ),
          double.parse(
            e.value.toString(),
          ),
        );
      },
    ).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          color: grad2Color,
          belowBarData: BarAreaData(
            show: true,
            color: primary.withOpacity(0.5),
          ),
          aboveBarData: BarAreaData(
            show: true,
            color: fontColor.withOpacity(0.2),
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, child) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: black,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(),
        topTitles: AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, child) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: black,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  //2. catChart

  LineChartData weekData(HomeProvider val) {
    if (val.weekEarning!.isEmpty) {
      val.weekEarning!.add(0);
      val.weeks!.add(0);
    }
    List<FlSpot> spots = val.weekEarning!.asMap().entries.map(
      (e) {
        return FlSpot(
          double.parse(e.key.toString()),
          double.parse(
            e.value.toString(),
          ),
        );
      },
    ).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          color: grad2Color,
          belowBarData: BarAreaData(
            show: true,
            color: primary.withOpacity(0.5),
          ),
          aboveBarData: BarAreaData(
            show: true,
            color: fontColor.withOpacity(0.2),
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, child) {
              return Text(
                val.weeks![value.toInt()].toString(),
                style: const TextStyle(
                  color: black,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(),
        topTitles: AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, child) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: black,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  //2. monthData

  LineChartData monthData(HomeProvider val) {
    if (val.monthEarning!.isEmpty) {
      val.monthEarning!.add(0);
      val.months!.add(0);
    }
    List<FlSpot> spots = val.monthEarning!.asMap().entries.map(
      (e) {
        return FlSpot(
          double.parse(e.key.toString()),
          double.parse(
            e.value.toString(),
          ),
        );
      },
    ).toList();
    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          color: grad2Color,
          belowBarData: BarAreaData(
            show: true,
            color: primary.withOpacity(0.5),
          ),
          aboveBarData: BarAreaData(
            show: true,
            color: fontColor.withOpacity(0.2),
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(),
        topTitles: AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, child) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: black,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, child) {
              return Text(
                val.months![value.toInt()].toString(),
                style: const TextStyle(
                  color: black,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  Color generateRandomColor() {
    Random random = Random();
    // Pick a random number in the range [0.0, 1.0)
    double randomDouble = random.nextDouble();

    return Color((randomDouble * 0xFFFFFF).toInt()).withOpacity(1.0);
  }
//==============================================================================
//========================= get_seller_details API =============================

  Future<void> getSallerDetail() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      CUR_USERID = await getPrefrence(Id);
      var parameter = {Id: CUR_USERID};
      apiBaseHelper.postAPICall(getSellerDetailsApi, parameter).then(
        (getdata) async {
          bool error = getdata["error"];
          if (!error) {
            var data = getdata["data"][0];
            CUR_BALANCE = double.parse(data[BALANCE]).toStringAsFixed(2);
            LOGO = data["logo"].toString();
            RATTING = data[Rating] ?? "";
            NO_OFF_RATTING = data[NoOfRatings] ?? "";
            var id = data[Id];
            var username = data[Username];
            var email = data[Email];
            mobile = data[Mobile];
            print("mobile : $mobile");
            var address = data[Address];
            CUR_USERID = id!;
            CUR_USERNAME = username!;
            var srorename = data[StoreName];
            var storeurl = data[Storeurl];
            var storeDesc = data[storeDescription];
            var accNo = data[accountNumber];
            var accname = data[accountName];
            var bankCode = data[BankCOde];
            var bankName = data[bankNAme];
            var latitutute = data[Latitude];
            var longitude = data[Longitude];
            var taxname = data[taxName];
            var taxNumber = data["tax_number"];
            var panNumber = data["pan_number"];
            var status = data[STATUS];
            var storeLogo = data[StoreLogo];
            saveUserDetail(
              id!,
              username!,
              mobile!,
              );
          }
          setState(
            () {
              _isLoading = false;
            },
          );
        },
        onError: (error) {
          setsnackbar(
            error.toString(),
            context,
          );
        },
      );
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
            _isLoading = false;
          },
        );
      }
    }

    return;
  }

//==============================================================================
//============================ AppBar ==========================================

  getAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        appName,
        style: TextStyle(
          color: grad2Color,
        ),
      ),
      backgroundColor: white,
      iconTheme: const IconThemeData(
        color: grad2Color,
      ),
    );
  }

//==============================================================================
//============================= Drawer Implimentation ==========================

  getDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: white,
          child: ListView(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              _getHeader(),
              const Divider(),
              _getDrawerItem(
                  0, getTranslated(context, "HOME")!, Icons.home_outlined),
              _getDrawerItem(1, getTranslated(context, "ORDERS")!,
                  Icons.shopping_basket_outlined),
              const Divider(),
              // _getDrawerItem(
              //     2, getTranslated(context, "CUSTOMERS")!, Icons.person),
              _getDrawerItem(3, getTranslated(context, "WALLETHISTORY")!,
                  Icons.account_balance_wallet_outlined),
              _getDrawerItem(4, getTranslated(context, "PRODUCTS")!,
                  Icons.production_quantity_limits_outlined),
              const Divider(),
              _getDrawerItem(10, "Add Product", Icons.add),
              _getDrawerItem(5, getTranslated(context, "ChangeLanguage")!,
                  Icons.translate),
              const Divider(),
              _getDrawerItem(6, getTranslated(context, "T_AND_C")!,
                  Icons.speaker_notes_outlined),
              _getDrawerItem(7, getTranslated(context, "PRIVACYPOLICY")!,
                  Icons.lock_outline),
              const Divider(),
              _getDrawerItem(
                  9, getTranslated(context, "CONTACTUS")!, Icons.contact_page),
              _getDrawerItem(11, getTranslated(context, "Return Policy")!,
                  Icons.assignment_returned_outlined),
              _getDrawerItem(12, getTranslated(context, "Shipping Policy")!,
                  Icons.local_shipping_outlined),
              const Divider(),
              _getDrawerItem(13, "Delete Account", Icons.delete),
              _getDrawerItem(
                  8, getTranslated(context, "LOGOUT")!, Icons.logout),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }

//  => Drawer Header

  _getHeader() {
    return InkWell(
      child: Container(
        decoration: back(),
        padding: const EdgeInsets.only(left: 10.0, bottom: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, left: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CUR_USERNAME!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                    Text(
                      getTranslated(context, "WALLET_BAL")! +
                          getPriceFormat(
                            context,
                            double.parse(CUR_BALANCE),
                          )!,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .caption!
                          .copyWith(color: white),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslated(context, "EDIT_PROFILE_LBL")!,
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .copyWith(color: white),
                          ),
                          const Icon(
                            Icons.arrow_right_outlined,
                            color: white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.only(top: 20, right: 20),
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1.0,
                    color: white,
                  ),
                ),
                child: LOGO != ''
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: sallerLogo(62),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(100.0),
                        child: imagePlaceHolder(62),
                      ),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => Profile(),
          ),
        ).then(
          (value) {
            providerRequiestForData();
            getSallerDetail();
            providerRequiestForData();
            setState(
              () {},
            );
            Navigator.pop(context);
          },
        );
        setState(
          () {},
        );
      },
    );
  }

  sallerLogo(double size) {
    return CircleAvatar(
      backgroundImage: NetworkImage(LOGO),
      radius: 25,
    );
  }

  imagePlaceHolder(double size) {
    return SizedBox(
      height: size,
      width: size,
      child: Icon(
        Icons.account_circle,
        color: Colors.white,
        size: size,
      ),
    );
  }

  _getDrawerItem(int index, String title, IconData icn) {
    return Container(
      margin: const EdgeInsets.only(
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: curDrwSel == index
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [secondary.withOpacity(0.2), primary.withOpacity(0.2)],
                stops: const [0, 1],
              )
            : null,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icn,
          color: curDrwSel == index ? primary : lightBlack2,
        ),
        title: Text(
          title,
          style: TextStyle(
              color: curDrwSel == index ? primary : lightBlack2, fontSize: 15),
        ),
        onTap: () {
          if (title == getTranslated(context, "HOME")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
          } else if (title == getTranslated(context, "ORDERS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => OrderList(),
              ),
            );
          } else if (title == getTranslated(context, "CUSTOMERS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const Customers(),
              ),
            );
          } else if (title == getTranslated(context, "WALLETHISTORY")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) =>
                    ChangeNotifierProvider<WalletTransactionProvider>(
                  create: (context) => WalletTransactionProvider(),
                  child: const WalletHistory(),
                ),
              ),
            );
          } else if (title == getTranslated(context, "PRODUCTS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProductList(
                  flag: '',
                ),
              ),
            );
          } else if (title == getTranslated(context, "ChangeLanguage")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            languageDialog();
          } else if (title == getTranslated(context, "T_AND_C")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ChangeNotifierProvider<SystemProvider>(
                  create: (context) => SystemProvider(),
                  child: Policy(
                    title: getTranslated(context, "TERM_CONDITIONS")!,
                  ),
                ),
              ),
            );
          } else if (title == "Delete Account") {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            currentIndex = 0;
            deleteAccountDailog();
          } else if (title == getTranslated(context, "CONTACTUS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ChangeNotifierProvider<SystemProvider>(
                  create: (context) => SystemProvider(),
                  child: Policy(
                    title: getTranslated(context, "CONTACTUS")!,
                  ),
                ),
              ),
            );
          } else if (title == getTranslated(context, "PRIVACYPOLICY")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);

            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ChangeNotifierProvider<SystemProvider>(
                  create: (context) => SystemProvider(),
                  child: Policy(
                    title: getTranslated(context, "PRIVACYPOLICY")!,
                  ),
                ),
              ),
            );
          } else if (title == getTranslated(context, "Return Policy")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);

            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ChangeNotifierProvider<SystemProvider>(
                  create: (context) => SystemProvider(),
                  child: Policy(
                    title: getTranslated(context, "Return Policy")!,
                  ),
                ),
              ),
            );
          } else if (title == getTranslated(context, "Shipping Policy")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);

            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ChangeNotifierProvider<SystemProvider>(
                  create: (context) => SystemProvider(),
                  child: Policy(
                    title: getTranslated(context, "Shipping Policy")!,
                  ),
                ),
              ),
            );
          } else if (title == getTranslated(context, "LOGOUT")!) {
            Navigator.pop(context);
            logOutDailog();
          } else if (title == "Add Product") {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const AddProduct(),
              ),
            );
          }
        },
      ),
    );
  }

//=================================== delete user dialog =======================
//==============================================================================

  deleteAccountDailog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (BuildContext context, setState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                //==================
                // when currentIndex == 0
                //==================
                currentIndex == 0
                    ? Text(
                        getTranslated(context, "Delete Account")!,
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle2!
                            .copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                    : Container(),
                currentIndex == 0
                    ? const SizedBox(
                        height: 10,
                      )
                    : Container(),
                currentIndex == 0
                    ? Text(
                        getTranslated(
                          context,
                          'Your all return order request, ongoing orders, wallet amount and also your all data will be deleted. So you will not able to access this account further. We understand if you want you can create new account to use this application.',
                        )!,
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle2!
                            .copyWith(),
                      )
                    : Container(),
                //==================
                // when currentIndex == 1
                //==================
                currentIndex == 1
                    ? Text(
                        getTranslated(context, "Please Verify Password")!,
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle2!
                            .copyWith(
                              color: black,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                    : Container(),
                currentIndex == 1
                    ? const SizedBox(
                        height: 25,
                      )
                    : Container(),
                currentIndex == 1
                    ? Container(
                        height: 53,
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                          color: lightWhite1,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        alignment: Alignment.center,
                        child: TextFormField(
                          style: TextStyle(
                              color: black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(passFocus);
                          },
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          controller: passwordController,
                          focusNode: passFocus,
                          textInputAction: TextInputAction.next,
                          onChanged: (String? value) {
                            verifyPassword = value;
                          },
                          onSaved: (String? value) {
                            verifyPassword = value;
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 5,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                                minWidth: 40, maxHeight: 20),
                            hintText: 'Password',
                            hintStyle: const TextStyle(
                                color: grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                            fillColor: lightWhite,
                            border: InputBorder.none,
                          ),
                        ),
                      )
                    : Container(),
                //==================
                // when currentIndex == 2
                //==================

                currentIndex == 2
                    ? const Center(child: CircularProgressIndicator())
                    : Container(),
                //==================
                // when currentIndex == 2
                //==================
                currentIndex == 3
                    ? Center(
                        child: Text(errorTrueMessage ??
                            "something Error Please Try again...!"),
                      )
                    : Container(),
              ],
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  currentIndex == 0
                      ? TextButton(
                          child: Text(
                            getTranslated(context, 'LOGOUTNO')!,
                            style: Theme.of(this.context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                  color: lightBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        )
                      : Container(),
                  currentIndex == 0
                      ? TextButton(
                          child: Text(
                            getTranslated(context, 'LOGOUTYES')!,
                            style: Theme.of(this.context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          onPressed: () {
                            setState(
                              () {
                                currentIndex = 1;
                              },
                            );
                          },
                        )
                      : Container(),
                ],
              ),
              currentIndex == 1
                  ? TextButton(
                      child: Text(
                        getTranslated(context, "Delete Now")!,
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle2!
                            .copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      onPressed: () async {
                        setState(
                          () {
                            currentIndex = 2;
                          },
                        );

                        //

                        await checkNetwork(mobile ?? "").then(
                          (value) {
                            setState(
                              () {
                                currentIndex = 3;
                              },
                            );
                          },
                        );
                      },
                    )
                  : Container(),
            ],
          );
        },
      ),
    );
  }

//=================================== Login API for Verfication ================
//==============================================================================

  Future<void> checkNetwork(
    String mobile,
  ) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      print("mobile number : $mobile");
      deleteAccountAPI(mobile);
    } else {
      Future.delayed(const Duration(seconds: 2)).then(
        (_) async {
          await buttonController!.reverse();
          if (mounted) {
            setState(
              () {
                _isNetworkAvail = false;
              },
            );
          }
        },
      );
    }
  }

  Future<void> deleteAccountAPI(String mobile) async {
    var data = {
      UserId: CUR_USERID,
      "mobile": mobile,
      "password": verifyPassword
    };
    print("parameter :$data");

    Response response =
        await post(deleteSellerApi, body: data, headers: headers)
            .timeout(const Duration(seconds: timeOut));
    var getdata = json.decode(response.body);
    print("getdata : $getdata");

    bool error = getdata['error'];
    String? msg = getdata['message'];
    print(getdata);
    if (!error) {
      currentIndex = 0;
      verifyPassword = "";
      setsnackbar(msg!, context);
      clearUserSession();
      Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(
            builder: (context) => const Login(),
          ),
          (Route<dynamic> route) => false);
    } else {
      errorTrueMessage = msg;
      currentIndex = 4;
      setState(() {});
      verifyPassword = "";
      //  Navigator.pop(context);
      setsnackbar(msg!, context);
    }
  }

//==============================================================================
//============================= Language Implimentation ========================

  languageDialog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setStater) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0.0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                  child: Text(
                    getTranslated(context, 'CHOOSE_LANGUAGE_LBL')!,
                    style: Theme.of(this.context).textTheme.subtitle1!.copyWith(
                          color: fontColor,
                        ),
                  ),
                ),
                const Divider(color: lightBlack),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: getLngList(context)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

//==============================================================================
//======================== Language List Generate ==============================

  List<Widget> getLngList(BuildContext ctx) {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  setState(
                    () {
                      selectLan = index;
                      _changeLan(langCode[index], ctx);
                    },
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 25.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectLan == index ? grad2Color : white,
                            border: Border.all(color: grad2Color),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: selectLan == index
                                ? const Icon(
                                    Icons.check,
                                    size: 17.0,
                                    color: white,
                                  )
                                : const Icon(
                                    Icons.check_box_outline_blank,
                                    size: 15.0,
                                    color: white,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 15.0,
                          ),
                          child: Text(
                            languageList[index]!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1!
                                .copyWith(color: lightBlack),
                          ),
                        )
                      ],
                    ),
                    index == languageList.length - 1
                        ? Container(
                            margin: const EdgeInsetsDirectional.only(
                              bottom: 10,
                            ),
                          )
                        : const Divider(
                            color: lightBlack,
                          ),
                  ],
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  void _changeLan(String language, BuildContext ctx) async {
    Locale locale = await setLocale(language);

    MyApp.setLocale(ctx, locale);
  }

//==============================================================================
//============================= Log-Out Implimentation =========================

  logOutDailog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Text(
                getTranslated(context, "LOGOUTTXT")!,
                style: Theme.of(this.context)
                    .textTheme
                    .subtitle1!
                    .copyWith(color: fontColor),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, "LOGOUTNO")!,
                    style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                        color: lightBlack, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, "LOGOUTYES")!,
                    style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                        color: fontColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    clearUserSession();
                    Navigator.of(context).pushAndRemoveUntil(
                        CupertinoPageRoute(
                          builder: (context) => const Login(),
                        ),
                        (Route<dynamic> route) => false);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

//==============================================================================
//=========================== Body Part Implimentation =========================

  getBodyPart() {
    return _isNetworkAvail
        ? Consumer<HomeProvider>(
            builder: (context, value, child) {
              chartList = {
                0: dayData(value),
                1: weekData(value),
                2: monthData(value)
              };

              if (value.getCurrentStatus == HomeProviderStatus.isSuccsess) {
                return _isLoading || supportedLocale == null
                    ? shimmer()
                    : RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: _refresh,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              left: 8,
                              right: 8,
                            ),
                            child: Column(
                              children: [
                                firstHeader(value),
                                secondHeader(value),
                                thirdHeader(value),
                                const SizedBox(
                                  height: 5,
                                ),
                                getChart(),
                                catChart(value),
                                const SizedBox(height: 15),
                              ],
                            ),
                          ),
                        ),
                      );
              } else if (value.getCurrentStatus ==
                  SystemProviderPolicyStatus.isFailure) {
                return shimmer();
              }
              return shimmer();
            },
          )
        : noInternet(context);
  }

//==============================================================================
//============================ Category Chart ==============================

  catChart(HomeProvider val) {
    Size size = MediaQuery.of(context).size;
    double width = size.width > size.height ? size.height : size.width;
    double ratio;
    if (width > 600) {
      ratio = 0.5;
      // Do something for tablets here
    } else {
      ratio = 0.8;
      // Do something for phones
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: AspectRatio(
        aspectRatio: 1.23,
        child: Card(
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  getTranslated(context, "CatWiseCount")!,
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: primary),
                ),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      height: 18,
                    ),
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: .8,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                    touchCallback: (fl, pieTouchResponse) {
                                  // ingnore abc
                                  setState(
                                    () {
                                      final desiredTouch =
                                          pieTouchResponse!.touchedSection
                                                  is! PointerExitEvent &&
                                              pieTouchResponse.touchedSection
                                                  is! PointerUpEvent;
                                      if (desiredTouch &&
                                          pieTouchResponse.touchedSection !=
                                              null) {
                                        touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      } else {
                                        touchedIndex = -1;
                                      }
                                    },
                                  );
                                }),
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                sectionsSpace: 0,
                                startDegreeOffset: 180,
                                centerSpaceRadius: 40,
                                sections: showingSections(val),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shrinkWrap: true,
                        itemCount: colorList.length,
                        itemBuilder: (context, i) {
                          return Indicators(
                            color: colorList[i],
                            text: val.catList![i] + " " + val.catCountList![i],
                            textColor:
                                touchedIndex == i ? Colors.black : Colors.grey,
                            isSquare: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections(HomeProvider val) {
    return List.generate(
      val.catCountList!.length,
      (i) {
        final isTouched = i == touchedIndex;

        final double fontSize = isTouched ? 25 : 16;
        final double radius = isTouched ? 60 : 50;

        return PieChartSectionData(
          color: colorList[i],
          value: double.parse(
            val.catCountList![i].toString(),
          ),
          title: "",
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            color: const Color(0xffffffff),
          ),
        );
      },
    );
  }

//==============================================================================
//============================ No Internet Widget ==============================

  noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      providerRequiestForData();
                      getSallerDetail();
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
          ],
        ),
      ),
    );
  }

//==============================================================================
//============================ Refresh Implimentation ==========================

  Future<void> _refresh() async {
    Completer<void> completer = Completer<void>();
    await Future.delayed(const Duration(seconds: 3)).then(
      (onvalue) {
        completer.complete();
        providerRequiestForData();
        getSallerDetail();
        setState(
          () {
            _isLoading = true;
          },
        );
      },
    );
    return completer.future;
  }

  @override
  void dispose() {
    passwordController.dispose();
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> callApi() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      await getSetting();
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
    return;
  }

  Future<void> providerRequiestForData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String getlng = await getPrefrence(LAGUAGE_CODE) ?? '';

    selectLan = langCode.indexOf(getlng == '' ? "en" : getlng);

    await context.read<HomeProvider>().allocateAllData();
  }

  Future<void> getSetting() async {
    Map parameter = {};

    apiBaseHelper.postAPICall(getSettingsApi, parameter).then(
      (getdata) async {
        bool error = getdata['error'];
        String? msg = getdata['message'];

        if (!error) {
          var data = getdata['data']['system_settings'][0];
          supportedLocale = data["supported_locals"];
          Is_APP_IN_MAINTANCE = data['is_seller_app_under_maintenance'];
          MAINTENANCE_MESSAGE = data['message_for_seller_app'];
          Decimal_Digits = data['decimal_point']; // Painding
          setState(
            () {},
          );
          if (Is_APP_IN_MAINTANCE == "1") {
            appMaintenanceDialog();
          }
        } else {
          setsnackbar(
            msg!,
            context,
          );
        }
      },
      onError: (error) {
        setsnackbar(
          error.toString(),
          context,
        );
      },
    );
  }

  void appMaintenanceDialog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setStater) {
          return WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              title: Text(
                getTranslated(context, 'APP_MAINTENANCE')!,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    child:
                        Lottie.asset('assets/animation/app_maintenance.json'),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Text(
                    MAINTENANCE_MESSAGE != ''
                        ? '$MAINTENANCE_MESSAGE'
                        : getTranslated(
                            context, 'MAINTENANCE_DEFAULT_MESSAGE')!,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
//==============================================================================
//==============================================================================
