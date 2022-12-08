import 'package:flutter/material.dart';
import '../Repository/getSettingRepositry.dart';

enum SystemProviderPolicyStatus {
  initial,
  inProgress,
  isSuccsess,
  isFailure,
  isMoreLoading,
}

class SystemProvider extends ChangeNotifier {
  SystemProviderPolicyStatus _systemProviderPolicyStatus =
      SystemProviderPolicyStatus.initial;

  String errorMessage = '';
  String policy = "";

  get getCurrentStatus => _systemProviderPolicyStatus;

  changeStatus(SystemProviderPolicyStatus status) {
    _systemProviderPolicyStatus = status;
    notifyListeners();
  }

  //get System Policies
  Future getSystemPolicies(String policyType) async {
    try {
      changeStatus(SystemProviderPolicyStatus.inProgress);

      var parameter = {};
      var result =
          await SystemRepository.fetchSystemPolicies(policyType: policyType);
      print(" provaciy policy : $policyType");
      print("result : ${result}");
      print("data : ${result['policy'][policyType][0].toString()}");
      policy = result['policy'][policyType][0].toString();

      changeStatus(SystemProviderPolicyStatus.isSuccsess);
    } catch (e) {
      print("error message : $e");
      errorMessage = e.toString();

      changeStatus(SystemProviderPolicyStatus.isFailure);
    }
  }
}
