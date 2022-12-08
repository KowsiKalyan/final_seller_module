import '../Helper/ApiBaseHelper.dart';
import '../Helper/String.dart';

class HomeRepository {
  //This method is used to fetch System policies {e.g. Privacy Policy, T&C etc..}
  static Future<String> fetchSalesReport({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      print(" parameter : $parameter");
      print("testing 2");
      var grandFinalTotal =
          await ApiBaseHelper().postAPICall(getSalesListApi, parameter);
      String temp = grandFinalTotal["grand_final_total"];
      print(" grandFinalTotal : $grandFinalTotal");
      return temp;
    } on Exception catch (e) {
      throw ApiException('Something went wrong');
    }
  }

  static Future<Map<String, dynamic>> fetchGetStatics({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var policy =
          await ApiBaseHelper().postAPICall(getStatisticsApi, parameter);
      print("we are here 111");
      return policy;
    } on Exception catch (e) {
      throw ApiException('Something went wrong');
    }
  }
}
