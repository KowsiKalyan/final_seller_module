import 'package:flutter/material.dart';
import 'package:sellermultivendor/Screen/Home.dart';
import 'dart:math';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Repository/homeRepositry.dart';

enum HomeProviderStatus {
  initial,
  inProgress,
  isSuccsess,
  isFailure,
  isMoreLoading,
}

class HomeProvider extends ChangeNotifier {
  HomeProviderStatus _systemProviderPolicyStatus = HomeProviderStatus.initial;

  String errorMessage = '';
  String grandFinalTotalOfSales = "";

  String? totalorderCount,
      totalproductCount,
      totalcustCount,
      totaldelBoyCount,
      totalsoldOutCount,
      totallowStockCount;
  List? weekEarning = [],
      days = [],
      dayEarning = [],
      months = [],
      monthEarning = [],
      catCountList = [],
      catList = [],
      weeks = [];
  get getCurrentStatus => _systemProviderPolicyStatus;

  changeStatus(HomeProviderStatus status) {
    _systemProviderPolicyStatus = status;
    notifyListeners();
  }

  //get Sales Report Request
  Future allocateAllData() async {
    CUR_USERID = await getPrefrence(Id);
    try {
      changeStatus(HomeProviderStatus.inProgress);
      var parameter = {
        SellerId: CUR_USERID,
      };
      var totalOFSales = await HomeRepository.fetchSalesReport(
        parameter: parameter,
      );

      grandFinalTotalOfSales = totalOFSales;
      var getStatics = await HomeRepository.fetchGetStatics(
        parameter: parameter,
      );

      CUR_CURRENCY = getStatics["currency_symbol"];
      var count = getStatics['counts'][0];
      totalorderCount = count["order_counter"];
      totalproductCount = count["product_counter"];
      totalsoldOutCount = count['count_products_sold_out_status'];
      totallowStockCount = count["count_products_low_status"];
      totalcustCount = count["user_counter"];
      delPermission = count["permissions"]['assign_delivery_boy'];
      weekEarning = getStatics['earnings'][0]["weekly_earnings"]['total_sale'];
      days = getStatics['earnings'][0]["daily_earnings"]['day'];
      dayEarning = getStatics['earnings'][0]["daily_earnings"]['total_sale'];
      months = getStatics['earnings'][0]["monthly_earnings"]['month_name'];
      monthEarning =
          getStatics['earnings'][0]["monthly_earnings"]['total_sale'];
      customerViewPermission = () {
        if (count["permissions"]['customer_privacy'] == "1") {
          return true;
        } else {
          return false;
        }
      }();
      weeks = getStatics['earnings'][0]["weekly_earnings"]['week'];
      var temp = getStatics['category_wise_product_count'];
      if (temp.toString() != "[]") {
        catCountList = getStatics['category_wise_product_count']['counter'];
        catList = getStatics['category_wise_product_count']['cat_name'];
        colorList.clear();
        for (int i = 0; i < catList!.length; i++) {
          colorList.add(generateRandomColor());
        }
      }

      changeStatus(HomeProviderStatus.isSuccsess);
    } catch (e) {
      errorMessage = e.toString();

      changeStatus(HomeProviderStatus.isFailure);
    }
  }

  Color generateRandomColor() {
    Random random = Random();
    // Pick a random number in the range [0.0, 1.0)
    double randomDouble = random.nextDouble();

    return Color((randomDouble * 0xFFFFFF).toInt()).withOpacity(1.0);
  }
}
