import 'package:sellermultivendor/Helper/String.dart';

import '../Helper/ApiBaseHelper.dart';

class SystemRepository {
  //
  //This method is used to fetch System policies {e.g. Privacy Policy, T&C etc..}
  static Future<Map<String, dynamic>> fetchSystemPolicies(
      {required String policyType}) async {
    try {
      var parameter = {};
      var policy = await ApiBaseHelper().postAPICall(getSettingsApi, parameter);

      return {'policy': policy['data']};
    } on Exception catch (e) {
      throw ApiException('Something went wrong');
    }
  }
}
