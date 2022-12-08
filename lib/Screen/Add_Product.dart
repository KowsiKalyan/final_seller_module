import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:sellermultivendor/Helper/Color.dart';
import 'package:sellermultivendor/Helper/Constant.dart';
import 'package:sellermultivendor/Helper/Session.dart';
import 'package:sellermultivendor/Helper/String.dart';
import 'package:sellermultivendor/Model/Attribute%20Models/AttributeModel/AttributesModel.dart';
import 'package:sellermultivendor/Model/Attribute%20Models/AttributeValueModel/AttributeValue.dart';
import 'package:sellermultivendor/Model/BrandModel/brandModel.dart';
import 'package:sellermultivendor/Model/ProductModel/Variants.dart';
import 'package:sellermultivendor/Screen/Home.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Helper/ProductDescription.dart';
import '../Model/Attribute Models/AttributeSetModel/AttributeSetModel.dart';
import '../Model/CategoryModel/categoryModel.dart';
import '../Model/TaxesModel/TaxesModel.dart';
import '../Model/ZipCodesModel/ZipCodeModel.dart';
import '../Model/city/cityModel.dart';
import 'Media.dart';
import 'Widgets/FilterChips.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({Key? key}) : super(key: key);

  @override
  _AddProductState createState() => _AddProductState();
}

late String productImage, productImageUrl, uploadedVideoName;
List<String> otherPhotos = [];
List<File>? otherPhotosFromGellery = [];
List<String> otherImageUrl = [];
List<Product_Varient> variationList = [];

class _AddProductState extends State<AddProduct> with TickerProviderStateMixin {
  //=========================== New UI variable =================================

  int currentPage = 1;

  //============================================================================
  int? selCityPos = -1;
  String? city;
  StateSetter? cityState;
  bool? isLoadingMoreCity;
  int cityOffset = 0;
  bool cityLoading = true;
  List<CityModel> citySearchLIst = [];
  final ScrollController _cityScrollController = ScrollController();
  bool _isProgress = false;
  List<CityModel> cityList = [];

//------------------------------------------------------------------------------
//======================= Variable Declaration =================================

// temprary variable for test
  late Map<String, List<AttributeValueModel>> selectedAttributeValues = {};

// => Variable For UI ...
  String? selectedCatName; // for UI

// brand name 
  String? selectedBrandName;
  String? selectedBrandId;

  int? selectedTaxID; // for UI
  var mainImageProductImage;
  final TextEditingController _cityController = TextEditingController();
//on-off toggles
  bool isToggled = false;
  bool isreturnable = false;
  bool isCODallow = false;
  bool iscancelable = false;
  bool taxincludedInPrice = false;

//for remove extra add
  int attributeIndiacator = 0;

// network variable
  bool _isNetworkAvail = true;
  String? data;
  bool suggessionisNoData = false;

//------------------------------------------------------------------------------
//                        Parameter For API Call

  String? productName; //pro_input_name
  String? sortDescription; // short_description
  String? tags; // Tags
  String? taxId; // Tax (pro_input_tax)
  String? indicatorValue; // indicator
  String? madeIn; //made_in
  String? totalAllowQuantity; // total_allowed_quantity
  String? minOrderQuantity; // minimum_order_quantity
  String? quantityStepSize; // quantity_step_size
  String? warrantyPeriod; //warranty_period
  String? guaranteePeriod; //guarantee_period
  String? deliverabletypeValue = "1"; //deliverable_type
  String? deliverableZipcodes; //deliverable_zipcodes
  String? taxincludedinPrice = "0"; //is_prices_inclusive_tax
  String? isCODAllow = "0"; //cod_allowed
  String? isReturnable = "0"; //is_returnable
  String? isCancelable = "0"; //is_cancelable
  String? tillwhichstatus; //cancelable_till
  //File? mainProductImage;//pro_input_image
  String? selectedTypeOfVideo; // video_type
  String? videoUrl; //video
  File? videoOfProduct; // pro_input_video
  String? description; // pro_input_description
  String? selectedCatID; //category_id
  //attribute_values
  String? productType; //product_type
  String? variantStockLevelType =
      "product_level"; //variant_stock_level_type // defualt is product level  if not pass
  int curSelPos = 0;

// for simple product   if(product_type == simple_product)

  String? simpleproductStockStatus = "1"; //simple_product_stock_status
  String? simpleproductPrice; //simple_price
  String? simpleproductSpecialPrice; //simple_special_price
  String? simpleproductSKU; // product_sku
  String? simpleproductTotalStock; // product_total_stock
  String? variantStockStatus =
      "0"; //variant_stock_status //fix according to riddhi mam =0 for simple product // not give any option for selection

// for variable product
  List<List<AttributeValueModel>> finalAttList = [];
  List<List<AttributeValueModel>> tempAttList = [];
  String? variantsIds; //variants_ids
  String? variantPrice; // variant_price
  String? variantSpecialPrice; // variant_special_price
  String? variantImages; // variant_images

  //{if (variant_stock_level_type == product_level)}
  String? variantproductSKU; //sku_variant_type
  String? variantproductTotalStock; // total_stock_variant_type
  String stockStatus = '1'; // variant_status

  //{if(variant_stock_level_type == variable_level)}
  String? variantSku; // variant_sku
  String? variantTotalStock; // variant_total_stock
  String? variantLevelStockStatus; //variant_level_stock_status
  bool? _isStockSelected;

//  other
  bool simpleProductSaveSettings = false;
  bool variantProductProductLevelSaveSettings = false;
  bool variantProductVariableLevelSaveSettings = false;
  late StateSetter taxesState;

  // getting data
  List<TaxesModel> taxesList = [];
  List<AttributeSetModel> attributeSetList = [];
  List<AttributeModel> attributesList = [];
  List<AttributeValueModel> attributesValueList = [];
  List<ZipCodeModel> zipSearchList = [];
  List<CategoryModel> catagorylist = [];
  final List<TextEditingController> _attrController = [];
  final List<TextEditingController> _attrValController = [];
  List<bool> variationBoolList = [];
  List<int> attrId = [];
  List<int> attrValId = [];
  List<String> attrVal = [];

  List<BrandModel> brandList = [];

//------------------------------------------------------------------------------
//======================= TextEditingController ================================

  TextEditingController productNameControlller = TextEditingController();
  TextEditingController sortDescriptionControlller = TextEditingController();
  TextEditingController tagsControlller = TextEditingController();
  TextEditingController totalAllowController = TextEditingController();
  TextEditingController minOrderQuantityControlller = TextEditingController();
  TextEditingController quantityStepSizeControlller = TextEditingController();
  TextEditingController madeInControlller = TextEditingController();
  TextEditingController warrantyPeriodController = TextEditingController();
  TextEditingController guaranteePeriodController = TextEditingController();
  TextEditingController vidioTypeController = TextEditingController();
  TextEditingController simpleProductPriceController = TextEditingController();
  TextEditingController simpleProductSpecialPriceController =
      TextEditingController();
  TextEditingController simpleProductSKUController = TextEditingController();
  TextEditingController simpleProductTotalStock = TextEditingController();
  TextEditingController variountProductSKUController = TextEditingController();
  TextEditingController variountProductTotalStock = TextEditingController();

//------------------------------------------------------------------------------
//=================================== FocusNode ================================
  late int row = 1, col;
  FocusNode? productFocus,
      sortDescriptionFocus,
      tagFocus,
      totalAllowFocus,
      minOrderFocus,
      quantityStepSizeFocus,
      madeInFocus,
      warrantyPeriodFocus,
      guaranteePeriodFocus,
      vidioTypeFocus,
      simpleProductPriceFocus,
      simpleProductSpecialPriceFocus,
      simpleProductSKUFocus,
      simpleProductTotalStockFocus,
      variountProductSKUFocus,
      variountProductTotalStockFocus,
      rawKeyboardListenerFocus,
      tempFocusNode,
      attributeFocus = FocusNode();

//------------------------------------------------------------------------------
//========================= For Form Validation ================================

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

//------------------------------------------------------------------------------
//======================= Delete this  ================================

  List<String> selectedAttribute = [];

  List<String> suggestedAttribute = [];

  bool showSuggestedAttributes = false;

  TextEditingController textEditingController = TextEditingController();

//------------------------------------------------------------------------------
//========================= For Animation ======================================

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

//------------------------------------------------------------------------------
//========================= InIt MEthod ========================================
  List<String> resultAttr = [];
  List<String> resultID = [];
  late int max;

  @override
  void initState() {
    productImage = "";
    productImageUrl = "";
    uploadedVideoName = "";
    _cityScrollController.addListener(_scrollListener);

    getZipCodes();
    getBrands();
    getCategories();
    getTax();
    getAttributesValue();
    getAttributes();
    getAttributeSet();
    getCities(false);
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    productImage = '';
    productImageUrl = '';
    uploadedVideoName = '';
    otherPhotos = [];
    otherImageUrl = [];
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
    super.initState();
  }

  _scrollListener() async {
    if (_cityScrollController.offset >=
            _cityScrollController.position.maxScrollExtent &&
        !_cityScrollController.position.outOfRange) {
      if (mounted) {
        setState(() {
          /*if (widget.section_model!.offset! <
                widget.section_model!.totalItem!) getSection('0');*/
        });

        cityState!(() {
          isLoadingMoreCity = true;
          _isProgress = true;
        });
        await getCities(false);
      }
    }
  }
//------------------------------------------------------------------------------
//======================== getAttributeSet API =================================

  Future<void> getZipCodes() async {
    var parameter = {};
    apiBaseHelper.postAPICall(getZipcodesApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          zipSearchList.clear();
          var data = getdata["data"];
          zipSearchList = (data as List)
              .map((data) => ZipCodeModel.fromJson(data))
              .toList();
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

  Future<void> getCategories() async {
    CUR_USERID = await getPrefrence(Id);
    var parameter = {
      SellerId: CUR_USERID,
    };
    apiBaseHelper.postAPICall(getCategoriesApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          catagorylist.clear();
          var data = getdata["data"];
          catagorylist = (data as List)
              .map((data) => CategoryModel.fromJson(data))
              .toList();
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

  Future<void> getBrands() async {
    CUR_USERID = await getPrefrence(Id);
    var parameter = {
      SellerId: CUR_USERID,
    };
    apiBaseHelper.postAPICall(getBrandsDataApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          brandList.clear();
          var data = getdata["data"];
          brandList = (data as List)
              .map((data) => BrandModel.fromJson(data))
              .toList();
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

  getAttributeSet() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getAttributeSetApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          attributeSetList = (data as List)
              .map(
                (data) => AttributeSetModel.fromJson(data),
              )
              .toList();
        } else {
          setsnackbar(
            msg,
            context,
          );
        }
        setState(
          () {},
        );
      } on TimeoutException catch (_) {
        setsnackbar(
          getTranslated(context, "somethingMSg")!,
          context,
        );
      }
    }
  }

//------------------------------------------------------------------------------
//======================== getAttributes API ===================================

  getAttributes() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getAttributesApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          attributesList = (data as List)
              .map(
                (data) => AttributeModel.fromJson(data),
              )
              .toList();
          for (var element in attributesList) {
            selectedAttributeValues[element.id!] = [];
          }

          setState(
            () {},
          );
        } else {
          setsnackbar(
            msg,
            context,
          );
        }
        setState(
          () {},
        );
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, "somethingMSg")!, context);
      }
    }
  }

//------------------------------------------------------------------------------
//======================== getAttributrValuesApi API ===========================

  getAttributesValue() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getAttributrValuesApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          attributesValueList = (data as List)
              .map(
                (data) => AttributeValueModel.fromJson(data),
              )
              .toList();
        } else {
          setsnackbar(
            msg,
            context,
          );
        }
        setState(
          () {},
        );
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, "somethingMSg")!, context);
      }
    }
  }

//------------------------------------------------------------------------------
//======================== getTax API ==========================================

  getTax() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getTaxesApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          taxesList =
              (data as List).map((data) => TaxesModel.fromJson(data)).toList();
        } else {
          setsnackbar(msg, context);
        }
        setState(
          () {},
        );
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, "somethingMSg")!, context);
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }
  }

//------------------------------------------------------------------------------
//============================== Tax Selection =================================

  taxesDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Tax")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                        Text(
                          getTranslated(context, "0%")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: getTaxtList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> getTaxtList() {
    return taxesList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  setState(
                    () {
                      selectedTaxID = index;
                      taxId = taxesList[selectedTaxID!].id;
                      Navigator.of(context).pop();
                    },
                  );
                }
              },
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(
                    20.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        taxesList[index].title!,
                      ),
                      Text(
                        "${taxesList[index].percentage!}%",
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

//------------------------------------------------------------------------------
//============================ attributeDialog ===================================

  attributeDialog(int pos) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          //    height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
                taxesState = setStater;
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                getTranslated(context, "Select Attribute")!,
                                style: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(color: fontColor),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: lightBlack),
                        suggessionisNoData
                            ? getNoItem(context)
                            : SizedBox(
                                width: double.maxFinite,
                                height: attributeSetList.isNotEmpty
                                    ? MediaQuery.of(context).size.height * 0.3
                                    : 0,
                                child: SingleChildScrollView(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: attributeSetList.length,
                                    itemBuilder: (context, index) {
                                      List<AttributeModel> attrList = [];

                                      AttributeSetModel item =
                                          attributeSetList[index];

                                      for (int i = 0;
                                          i < attributesList.length;
                                          i++) {
                                        if (item.id ==
                                            attributesList[i].attributeSetId) {
                                          attrList.add(attributesList[i]);
                                        }
                                      }
                                      return Material(
                                        child: StickyHeaderBuilder(
                                          builder: (BuildContext context,
                                              double stuckAmount) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                  color: primary,
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 2),
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                attributeSetList[index].name ??
                                                    '',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            );
                                          },
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List<int>.generate(
                                                attrList.length, (i) => i).map(
                                              (item) {
                                                return InkWell(
                                                  onTap: () {
                                                    setState(
                                                      () {
                                                        _attrController[pos]
                                                                .text =
                                                            attrList[item]
                                                                .name!;
                                                        attributeIndiacator =
                                                            pos + 1;
                                                        if (!attrId.contains(
                                                            int.parse(
                                                                attrList[item]
                                                                    .id!))) {
                                                          attrId.add(int.parse(
                                                              attrList[item]
                                                                  .id!));
                                                          Navigator.pop(
                                                              context);
                                                        } else {
                                                          setsnackbar(
                                                            getTranslated(
                                                                context,
                                                                "Already inserted..")!,
                                                            context,
                                                          );
                                                        }
                                                      },
                                                    );
                                                  },
                                                  child: Container(
                                                    width: double.maxFinite,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      attrList[item].name ?? '',
                                                      textAlign:
                                                          TextAlign.start,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  indicatorDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Indicator")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  indicatorValue = '0';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "None")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  indicatorValue = '1';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Veg")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  indicatorValue = '2';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Non-Veg")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//=================================== Made In ==================================

  cityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            cityState = setStater;

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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      getTranslated(context, "Made In")!,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle1!
                          .copyWith(color: fontColor),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: _cityController,
                            autofocus: false,
                            style: const TextStyle(
                              color: fontColor,
                            ),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                              /* prefixIcon: const Icon(Icons.search,
                                  color: colors.primary, size: 17),*/
                              hintText: getTranslated(context, 'SEARCH_LBL'),
                              hintStyle:
                                  TextStyle(color: primary.withOpacity(0.5)),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            // onChanged: (query) => updateSearchQuery(query),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: IconButton(
                            onPressed: () async {
                              setState(() {
                                isLoadingMoreCity = true;
                              });

                              await getCities(true);
                            },
                            icon: const Icon(
                              Icons.search,
                              size: 20,
                            )),
                      )
                    ],
                  ),
                  cityLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 50.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : (citySearchLIst.isNotEmpty)
                          ? Flexible(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: SingleChildScrollView(
                                  controller: _cityScrollController,
                                  child: Stack(
                                    children: [
                                      Column(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: getCityList(),
                                          ),
                                          Center(
                                            child: showCircularProgress(
                                                isLoadingMoreCity!, primary),
                                          ),
                                        ],
                                      ),
                                      showCircularProgress(
                                          _isProgress, primary),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: getNoItem(context),
                            )
                ],
              ),
            );
          },
        );
      },
    );
  }

  getCityList() {
    return citySearchLIst
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  madeIn = citySearchLIst[index].name;
                  setState(
                    () {
                      selCityPos = index;

                      Navigator.of(context).pop();
                    },
                  );
                }
                city = citySearchLIst[selCityPos!].id;
              },
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    citySearchLIst[index].name!,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  Future<void> getCities(bool isSearchCity) async {
    try {
      var parameter = {
        LIMIT: perPage.toString(),
        OFFSET: cityOffset.toString(),
      };

      if (isSearchCity) {
        parameter[SEARCH] = _cityController.text;
        parameter[OFFSET] = '0';
        citySearchLIst.clear();
      }
      Response response =
          await post(getCountriesDataApi, body: parameter, headers: headers)
              .timeout(const Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      bool error = getdata['error'];
      String? msg = getdata['message'];
      if (!error) {
        var data = getdata['data'];
        cityList =
            (data as List).map((data) => CityModel.fromJson(data)).toList();
        citySearchLIst.addAll(cityList);
      } else {
        if (msg != null) {
          setsnackbar(msg, context);
        }
      }
      cityLoading = false;
      isLoadingMoreCity = false;
      _isProgress = false;
      cityOffset += perPage;
      if (mounted && cityState != null) cityState!(() {});
      if (mounted) setState(() {});
    } on TimeoutException catch (_) {
      setsnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

//------------------------------------------------------------------------------
//============================ Deliverable Type ================================

  deliverableTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Deliverable Type")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '0';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "None")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '1';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "All")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '2';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Include")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '3';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Exclude")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//============================ Selected Pin codes Type =========================

  selectZipcode() {
    return deliverabletypeValue == "2" || deliverabletypeValue == "3"
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 5,
                        bottom: 5,
                        left: 5,
                        right: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: lightBlack,
                          width: 1,
                        ),
                      ),
                      child: deliverableZipcodes == null
                          ? Text(
                              getTranslated(context, "Select ZipCode")!,
                            )
                          : Text("$deliverableZipcodes"),
                    ),
                    onTap: () {
                      zipcodeDialog();
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                deliverableZipcodes == null
                    ? Container()
                    : InkWell(
                        onTap: () {
                          setState(
                            () {
                              deliverableZipcodes = null;
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: black),
                          ),
                          child: const Icon(Icons.close, color: red),
                        ),
                      ),
              ],
            ),
          )
        : Container();
  }

  zipcodeDialog() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          //   height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, setStater) {
              taxesState = setStater;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      getTranslated(context, "Select Zipcodes")!,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle1!
                          .copyWith(color: fontColor),
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: () {
                          bool flag = false;
                          return zipSearchList
                              .asMap()
                              .map(
                                (index, element) => MapEntry(
                                  index,
                                  InkWell(
                                    onTap: () {
                                      if (!flag) {
                                        flag = true;
                                      }
                                      if (mounted) {
                                        setState(
                                          () {
                                            if (deliverableZipcodes == null) {
                                              deliverableZipcodes =
                                                  zipSearchList[index].zipcode;
                                            } else if (deliverableZipcodes!
                                                .contains(zipSearchList[index]
                                                        .zipcode! +
                                                    ',')) {
                                              var a = zipSearchList[index]
                                                      .zipcode! +
                                                  ',';
                                              var b = deliverableZipcodes!
                                                  .replaceAll(a, '');

                                              deliverableZipcodes = b;
                                            } else if (deliverableZipcodes!
                                                .contains(zipSearchList[index]
                                                    .zipcode!)) {
                                              var a =
                                                  zipSearchList[index].zipcode!;
                                              var b = deliverableZipcodes!
                                                  .replaceAll(a, "");
                                              deliverableZipcodes = b;
                                            } else if (deliverableZipcodes!
                                                .endsWith(',')) {
                                              deliverableZipcodes =
                                                  "${deliverableZipcodes!}${zipSearchList[index].zipcode!}";
                                            } else {
                                              deliverableZipcodes =
                                                  "${deliverableZipcodes!},${zipSearchList[index].zipcode!}";
                                            }
                                          },
                                        );
                                      }
                                      setStater(() => {});
                                      setState(() {});
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: deliverableZipcodes != null &&
                                                  deliverableZipcodes!.contains(
                                                      zipSearchList[index]
                                                          .zipcode!)
                                              ? Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: grey2,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      height: 16,
                                                      width: 16,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: grey2,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      height: 16,
                                                      width: 16,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        Expanded(
                                          flex: 8,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              zipSearchList[index].zipcode!,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .values
                              .toList();
                        }(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text(getTranslated(context, "CANCEL")!,
                            style: TextStyle(
                              color: Colors.black,
                            )),
                        onPressed: () {
                          deliverableZipcodes = null;
                          setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: Text(
                          getTranslated(context, "Ok")!,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

//------------------------------------------------------------------------------
//========================= select Category Header =============================

  brandSelectButtomSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.arrow_back),
                        const Text(
                         "Select Brand",
                        ),
                        Container(width: 2),
                      ],
                    ),
                  ),
                  Center(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsetsDirectional.only(
                          bottom: 5, start: 10, end: 10),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: brandList.length,
                      itemBuilder: (context, index) {
                        BrandModel? item;

                        item =
                            brandList.isEmpty ? null : brandList[index];

                        return item == null ? Container() : getbrands(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  
  getbrands(int index) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
              selectedBrandName = brandList[index].name;
              selectedBrandId = brandList[index].id;
              setState(() {});
            },
            child: Column(
              children: [
                const Divider(),
                Row(
                  children: [
                    selectedBrandId == brandList[index].id
                        ? Container(
                            height: 20,
                            width: 20,
                            decoration: const BoxDecoration(
                              color: grey2,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                height: 16,
                                width: 16,
                                decoration: const BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: 20,
                            width: 20,
                            decoration: const BoxDecoration(
                              color: grey2,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                height: 16,
                                width: 16,
                                decoration: const BoxDecoration(
                                  color: white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: width * 0.6,
                      child: Text(
                        brandList[index].name!,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
          
        ],
      ),
    );
  }


  categorySelectButtomSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.arrow_back),
                        Text(
                          getTranslated(context, "Select Category")!,
                        ),
                        Container(width: 2),
                      ],
                    ),
                  ),
                  Center(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsetsDirectional.only(
                          bottom: 5, start: 10, end: 10),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: catagorylist.length,
                      itemBuilder: (context, index) {
                        CategoryModel? item;

                        item =
                            catagorylist.isEmpty ? null : catagorylist[index];

                        return item == null ? Container() : getCategorys(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  getCategorys(int index) {
    CategoryModel model = catagorylist[index];
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
              selectedCatName = model.name;
              selectedCatID = model.id;
              setState(() {});
            },
            child: Column(
              children: [
                const Divider(),
                Row(
                  children: [
                    selectedCatID == model.id
                        ? Container(
                            height: 20,
                            width: 20,
                            decoration: const BoxDecoration(
                              color: grey2,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                height: 16,
                                width: 16,
                                decoration: const BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: 20,
                            width: 20,
                            decoration: const BoxDecoration(
                              color: grey2,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                height: 16,
                                width: 16,
                                decoration: const BoxDecoration(
                                  color: white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: width * 0.6,
                      child: Text(
                        model.name!,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
          SizedBox(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.only(
                  bottom: 5, start: 15, end: 15),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: model.children!.length,
              itemBuilder: (context, index) {
                CategoryModel? item1;
                item1 = model.children!.isEmpty ? null : model.children![index];
                return item1 == null
                    ? SizedBox(
                        child: Text(
                          getTranslated(context, "no sub cat")!,
                        ),
                      )
                    : Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              selectedCatName = item1!.name;
                              selectedCatID = item1.id;
                              setState(() {});
                            },
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    selectedCatID == item1.id
                                        ? Container(
                                            height: 20,
                                            width: 20,
                                            decoration: const BoxDecoration(
                                              color: grey2,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Container(
                                                height: 16,
                                                width: 16,
                                                decoration: const BoxDecoration(
                                                  color: primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            height: 20,
                                            width: 20,
                                            decoration: const BoxDecoration(
                                              color: grey2,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Container(
                                                height: 16,
                                                width: 16,
                                                decoration: const BoxDecoration(
                                                  color: white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    SizedBox(
                                      width: width * 0.62,
                                      child: Text(
                                        item1.name!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                          SizedBox(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsetsDirectional.only(
                                  bottom: 5, start: 10, end: 10),
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: item1.children!.length,
                              itemBuilder: (context, index) {
                                CategoryModel? item2;
                                item2 = item1!.children!.isEmpty
                                    ? null
                                    : item1.children![index];
                                return item2 == null
                                    ? Container()
                                    : Column(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              selectedCatName = item2!.name;
                                              selectedCatID = item2.id;
                                              Navigator.pop(context);
                                              setState(() {});
                                            },
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    selectedCatID == item2.id
                                                        ? Container(
                                                            height: 20,
                                                            width: 20,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color: grey2,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Center(
                                                              child: Container(
                                                                height: 16,
                                                                width: 16,
                                                                decoration:
                                                                    const BoxDecoration(
                                                                  color:
                                                                      primary,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Container(
                                                            height: 20,
                                                            width: 20,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color: grey2,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Center(
                                                              child: Container(
                                                                height: 16,
                                                                width: 16,
                                                                decoration:
                                                                    const BoxDecoration(
                                                                  color: white,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    SizedBox(
                                                      width: width * 0.42,
                                                      child: Text(
                                                        item2.name!,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              padding:
                                                  const EdgeInsetsDirectional
                                                          .only(
                                                      bottom: 5,
                                                      start: 10,
                                                      end: 10),
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: item2.children!.length,
                                              itemBuilder: (context, index) {
                                                CategoryModel? item3;
                                                item3 = item2!.children!.isEmpty
                                                    ? null
                                                    : item2.children![index];
                                                return item3 == null
                                                    ? Container()
                                                    : Column(
                                                        children: [
                                                          InkWell(
                                                            onTap: () {
                                                              selectedCatName =
                                                                  item3!.name;
                                                              selectedCatID =
                                                                  item3.id;
                                                              Navigator.pop(
                                                                  context);
                                                              setState(
                                                                () {},
                                                              );
                                                            },
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    selectedCatID ==
                                                                            item3.id
                                                                        ? Container(
                                                                            height:
                                                                                20,
                                                                            width:
                                                                                20,
                                                                            decoration:
                                                                                const BoxDecoration(
                                                                              color: grey2,
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                Center(
                                                                              child: Container(
                                                                                height: 16,
                                                                                width: 16,
                                                                                decoration: const BoxDecoration(
                                                                                  color: primary,
                                                                                  shape: BoxShape.circle,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          )
                                                                        : Container(
                                                                            height:
                                                                                20,
                                                                            width:
                                                                                20,
                                                                            decoration:
                                                                                const BoxDecoration(
                                                                              color: grey2,
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                Center(
                                                                              child: Container(
                                                                                height: 16,
                                                                                width: 16,
                                                                                decoration: const BoxDecoration(
                                                                                  color: white,
                                                                                  shape: BoxShape.circle,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                    const SizedBox(
                                                                      width: 5,
                                                                    ),
                                                                    Text(item3
                                                                        .name!),
                                                                  ],
                                                                ),
                                                                const Divider(),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            child: ListView
                                                                .builder(
                                                              shrinkWrap: true,
                                                              padding:
                                                                  const EdgeInsetsDirectional
                                                                          .only(
                                                                      bottom: 5,
                                                                      start: 10,
                                                                      end: 10),
                                                              physics:
                                                                  const NeverScrollableScrollPhysics(),
                                                              itemCount: item3
                                                                  .children!
                                                                  .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                CategoryModel?
                                                                    item4;
                                                                item4 = item3!
                                                                        .children!
                                                                        .isEmpty
                                                                    ? null
                                                                    : item3.children![
                                                                        index];
                                                                return item4 ==
                                                                        null
                                                                    ? Container()
                                                                    : Column(
                                                                        children: [
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {});
                                                                              selectedCatName = item4!.name;
                                                                              selectedCatID = item4.id;
                                                                            },
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                const SizedBox(
                                                                                  width: 10,
                                                                                ),
                                                                                const Icon(
                                                                                  Icons.subdirectory_arrow_right_outlined,
                                                                                  color: primary,
                                                                                  size: 20,
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                Text(item4.name!),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            child:
                                                                                ListView.builder(
                                                                              shrinkWrap: true,
                                                                              padding: const EdgeInsetsDirectional.only(bottom: 5, start: 10, end: 10),
                                                                              physics: const NeverScrollableScrollPhysics(),
                                                                              itemCount: item4.children!.length,
                                                                              itemBuilder: (context, index) {
                                                                                CategoryModel? item5;
                                                                                item5 = item4!.children!.isEmpty ? null : item4.children![index];
                                                                                return item5 == null
                                                                                    ? Container()
                                                                                    : Column(
                                                                                        children: [
                                                                                          InkWell(
                                                                                            onTap: () {
                                                                                              setState(() {});
                                                                                              selectedCatName = item5!.name;
                                                                                              selectedCatID = item5.id;
                                                                                            },
                                                                                            child: Row(
                                                                                              children: [
                                                                                                const SizedBox(
                                                                                                  width: 10,
                                                                                                ),
                                                                                                const Icon(
                                                                                                  Icons.subdirectory_arrow_right_outlined,
                                                                                                  color: secondary,
                                                                                                  size: 20,
                                                                                                ),
                                                                                                const SizedBox(
                                                                                                  width: 5,
                                                                                                ),
                                                                                                Text(item5.name!),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                              },
                            ),
                          ),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

//------------------------------------------------------------------------------
//============================= Till which status ==============================

  tillWhichStatusDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  tillwhichstatus = 'received';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "RECEIVED_LBL")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  tillwhichstatus = 'processed';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "PROCESSED_LBL")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  tillwhichstatus = 'shipped';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "SHIPED_LBL")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  selectedMainImageShow() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        productImageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

//------------------------------------------------------------------------------
//========================= Other Image ========================================

  otherImages(String from, int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getPrimaryCommanText(getTranslated(context, "Other Images")!, true),
          InkWell(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: primary,
              ),
              width: 100,
              height: 35,
              child: Center(
                child: Text(
                  getTranslated(context, "Upload")!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => Media(
                    from: from,
                    pos: pos,
                    type: "add",
                  ),
                ),
              ).then(
                (value) => setState(
                  () {},
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  variantOtherImageShow(int pos) {
    return variationList.length == pos || variationList[pos].imagesUrl == null
        ? Container()
        : SizedBox(
            width: double.infinity,
            height: 130,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: variationList[pos].imagesUrl!.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          right: 8.0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            variationList[pos].imagesUrl![i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (mounted) {
                            setState(
                              () {
                                variationList[pos].imagesUrl!.removeAt(i);
                              },
                            );
                          }
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                          child: const Icon(
                            Icons.clear,
                            size: 15,
                            color: white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  uploadedOtherImageShow() {
    return otherImageUrl.isEmpty
        ? Container()
        : SizedBox(
            width: double.infinity,
            height: 130,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: otherPhotos.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          right: 8.0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            otherImageUrl[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (mounted) {
                            otherPhotos.removeAt(i);
                            otherImageUrl.removeAt(i);
                            setState(
                              () {},
                            );
                          }
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                          child: const Icon(
                            Icons.clear,
                            size: 15,
                            color: white,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          );
  }

//------------------------------------------------------------------------------
//========================= Main Image =========================================

  videoUpload() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getTranslated(context, "Video * ")!,
          ),
          InkWell(
            child: Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(5),
              ),
              width: 90,
              height: 40,
              child: Center(
                child: Text(
                  getTranslated(context, "Upload")!,
                  style: const TextStyle(
                    color: white,
                  ),
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const Media(
                    from: "video",
                    pos: 0,
                    type: "add",
                  ),
                ),
              ).then((value) => setState(() {}));
            },
          ),
        ],
      ),
    );
  }

  selectedVideoShow() {
    return uploadedVideoName == ''
        ? Container()
        : SizedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Text(uploadedVideoName)),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          );
  }

//------------------------------------------------------------------------------
//========================= Video Type =========================================

  videoselectionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Video Type")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = null;
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "None")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = 'vimeo';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Vimeo")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = 'youtube';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Youtube")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = 'Self Hosted';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(
                                        context,
                                        "Self Hosted",
                                      )!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//========================= Video Type =========================================

  videoUrlEnterField(String hinttitle) {
    return Container(
      height: 65,
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(vidioTypeFocus);
        },
        keyboardType: TextInputType.text,
        controller: vidioTypeController,
        style: const TextStyle(
          color: fontColor,
          fontWeight: FontWeight.normal,
        ),
        focusNode: vidioTypeFocus,
        textInputAction: TextInputAction.next,
        onChanged: (String? value) {
          videoUrl = value;
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: lightWhite,
          hintText: hinttitle,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 20),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: fontColor),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: lightWhite),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

//------------------------------------------------------------------------------
//========================= Additional Info ====================================

// logic painding

  additionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () {
                  setState(
                    () {
                      curSelPos = 0;
                    },
                  );
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: curSelPos == 0 ? primary : const Color(0xfff5f5f5),
                  ),
                  child: Center(
                    child: Text(
                      getTranslated(context, "General Information")!,
                      style: TextStyle(
                        color: curSelPos == 0 ? white : black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () {
                  setState(
                    () {
                      curSelPos = 1;
                    },
                  );
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: curSelPos == 1 ? primary : const Color(0xfff5f5f5),
                  ),
                  child: Center(
                    child: Text(
                      getTranslated(context, "Attributes")!,
                      style: TextStyle(
                        color: curSelPos == 1 ? white : black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            productType == 'variable_product'
                ? Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () {
                        setState(
                          () {
                            curSelPos = 2;
                          },
                        );
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: curSelPos == 2
                              ? primary
                              : const Color(0xfff5f5f5),
                        ),
                        child: Center(
                          child: Text(
                            getTranslated(context, "Variations")!,
                            style: TextStyle(
                              color: curSelPos == 2 ? white : black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
        curSelPos == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getCommanSizedBox(),
                  getPrimaryCommanText(
                      getTranslated(context, "Type Of Product")!, false),
                  getCommanSizedBox(),

                  getIconSelectionDesing(
                      getTranslated(context, "Select Type")!, 9),
                  productType == 'simple_product'
                      ? getCommanSizedBox()
                      : Container(),
                  productType == 'simple_product'
                      ? getCommanSizedBox()
                      : Container(),
                  productType == 'simple_product'
                      ? Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: getPrimaryCommanText(
                                  getTranslated(context, "PRICE_LBL")!, true),
                            ),
                            Expanded(
                              flex: 3,
                              child: getCommanInputTextField(
                                //logic painding
                                " ",
                                10,
                                0.06,
                                1,
                                3,
                              ),
                            ),
                          ],
                        )
                      : Container(),
                  // For Simple Product

                  productType == 'simple_product'
                      ? getCommanSizedBox()
                      : Container(),

                  productType == 'simple_product'
                      ? Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: getPrimaryCommanText(
                                  getTranslated(context, "Special Price")!,
                                  true),
                            ),
                            Expanded(
                              flex: 3,
                              child: getCommanInputTextField(
                                //logic painding
                                " ",
                                11,
                                0.06,
                                1,
                                3,
                              ),
                            ),
                          ],
                        )
                      : Container(),
                  productType == 'simple_product'
                      ? getCommanSizedBox()
                      : Container(),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: getPrimaryCommanText(
                            getTranslated(context, "Enable Stock Management")!,
                            true),
                      ),
                      Expanded(
                        flex: 2,
                        child: CheckboxListTile(
                          value: _isStockSelected ?? false,
                          onChanged: (bool? value) {
                            setState(
                              () {
                                _isStockSelected = value!;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  _isStockSelected != null &&
                          _isStockSelected == true &&
                          productType == 'simple_product'
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: getPrimaryCommanText(
                                      getTranslated(context, "SKU")!, true),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: getCommanInputTextField(
                                    //logic painding
                                    " ",
                                    12,
                                    0.06,
                                    1,
                                    2,
                                  ),
                                ),
                              ],
                            ),
                            getCommanSizedBox(),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: getPrimaryCommanText(
                                      getTranslated(context, "Total Stock")!,
                                      true),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: getCommanInputTextField(
                                    //logic painding
                                    " ",
                                    13,
                                    0.06,
                                    1,
                                    3,
                                  ),
                                ),
                              ],
                            ),
                            getCommanSizedBox(),
                            getIconSelectionDesing(
                                getTranslated(context, "Select Stock Status")!,
                                10),
                          ],
                        )
                      : Container(),
                  // _isStockSelected != null &&
                  //         _isStockSelected == true &&
                  //         productType == 'simple_product'
                  //     ? simpleProductSKU()
                  //     : Container(),
                  productType == 'simple_product'
                      ? getCommanSizedBox()
                      : Container(),
                  productType == 'simple_product'
                      ? getCommanSizedBox()
                      : Container(),
                  productType == 'simple_product'
                      ? getCommonButton(
                          getTranslated(context, "Save Settings")!, 4)
                      : Container(),

                  // varible product
                  _isStockSelected != null &&
                          _isStockSelected == true &&
                          productType == 'variable_product'
                      ? getPrimaryCommanText(
                          getTranslated(
                              context, "Choose Stock Management Type")!,
                          false)
                      : Container(),
                  productType == 'variable_product'
                      ? getCommanSizedBox()
                      : Container(),
                  _isStockSelected != null &&
                          _isStockSelected == true &&
                          productType == 'variable_product'
                      ? getIconSelectionDesing(
                          getTranslated(context, "Select Stock Status")!, 11)
                      : Container(),
                  // _isStockSelected != null &&
                  //         _isStockSelected == true &&
                  //         productType == 'variable_product'
                  //     ? variableProductStockManagementType()
                  //     : Container(),

                  productType == 'variable_product' &&
                          variantStockLevelType == "product_level" &&
                          _isStockSelected != null &&
                          _isStockSelected == true
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            getCommanSizedBox(),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: getPrimaryCommanText(
                                      getTranslated(context, "SKU")!, true),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: getCommanInputTextField(
                                    //logic painding
                                    " ",
                                    14,
                                    0.06,
                                    1,
                                    2,
                                  ),
                                ),
                              ],
                            ),

                            getCommanSizedBox(),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: getPrimaryCommanText(
                                      getTranslated(context, "Total Stock")!,
                                      true),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: getCommanInputTextField(
                                    //logic painding
                                    " ",
                                    15,
                                    0.06,
                                    1,
                                    3,
                                  ),
                                ),
                              ],
                            ),
                            //   variableProductSKU(),
                            // variantProductTotalstock(),
                            getPrimaryCommanText("Stock Status", false),
                            getCommanSizedBox(),
                            getIconSelectionDesing(
                                getTranslated(context, "Select Stock Status")!,
                                12),
                          ],
                        )
                      : Container(),
                  getCommanSizedBox(),
                  getCommanSizedBox(),

                  productType == 'variable_product' &&
                          variantStockLevelType == "product_level"
                      ? getCommonButton(
                          getTranslated(context, "Save Settings")!, 5)
                      : Container(),

                  productType == 'variable_product' &&
                          variantStockLevelType == "variable_level"
                      ? getCommonButton(
                          getTranslated(context, "Save Settings")!, 6)
                      : Container(),
                ],
              )
            : Container(),

// current selected possition == 1

        curSelPos == 1 &&
                (simpleProductSaveSettings ||
                    variantProductVariableLevelSaveSettings ||
                    variantProductProductLevelSaveSettings)
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  getCommanSizedBox(),
                  getCommanSizedBox(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getPrimaryCommanText(
                          getTranslated(context, "Attributes")!, false),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              if (attributeIndiacator ==
                                  _attrController.length) {
                                setState(() {
                                  _attrController.add(TextEditingController());
                                  _attrValController
                                      .add(TextEditingController());
                                  variationBoolList.add(false);
                                });
                              } else {
                                setsnackbar(
                                  getTranslated(context,
                                      "fill the box then add another")!,
                                  context,
                                );
                              }
                            },
                            child: Text(
                                getTranslated(context, "Add Attribute")!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              tempAttList.clear();
                              List<String> attributeIds = [];
                              for (var i = 0;
                                  i < variationBoolList.length;
                                  i++) {
                                if (variationBoolList[i]) {
                                  final attributes = attributesList
                                      .where((element) =>
                                          element.name ==
                                          _attrController[i].text)
                                      .toList();
                                  if (attributes.isNotEmpty) {
                                    attributeIds.add(attributes.first.id!);
                                  }
                                }
                              }
                              setState(
                                () {
                                  resultAttr = [];
                                  resultID = [];
                                  variationList = [];
                                  finalAttList = [];
                                  for (var key in attributeIds) {
                                    tempAttList
                                        .add(selectedAttributeValues[key]!);
                                  }
                                  for (int i = 0; i < tempAttList.length; i++) {
                                    finalAttList.add(tempAttList[i]);
                                  }
                                  if (finalAttList.isNotEmpty) {
                                    max = finalAttList.length - 1;

                                    getCombination([], [], 0);
                                    row = 1;
                                    col = max + 1;
                                    for (int i = 0; i < col; i++) {
                                      int singleRow = finalAttList[i].length;
                                      row = row * singleRow;
                                    }
                                  }
                                  setsnackbar(
                                    getTranslated(context,
                                        "Attributes saved successfully")!,
                                    context,
                                  );
                                },
                              );
                            },
                            child: Text(
                              getTranslated(context, "Save Attribute")!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  getCommanSizedBox(),
                  productType == 'variable_product'
                      ? Text(
                          getTranslated(
                            context,
                            "Note : select checkbox if the attribute is to be used for variation",
                          )!,
                        )
                      : Container(),
                  getCommanSizedBox(),
                  for (int i = 0; i < _attrController.length; i++)
                    addAttribute(i)
                ],
              )
            : Container(),
        curSelPos == 2 && variationList.isNotEmpty
            ? ListView.builder(
                itemCount: row,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFFececec),
                          style: BorderStyle.solid,
                          width: 1.0,
                        ),
                      ),
                      //    color: Colors.red,
                      child: ExpansionTile(
                        textColor: Colors.green,
                        title: Row(
                          children: [
                            for (int j = 0; j < col; j++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                      variationList[i].attr_name!.split(',')[j],
                                      style: const TextStyle(
                                        color: Color(0xFF999999),
                                      )),
                                ),
                              ),
                            InkWell(
                              child: const Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Icon(
                                  Icons.close,
                                  color: Color(0xFF999999),
                                ),
                              ),
                              onTap: () {
                                variationList.removeAt(i);
                                row = row - 1;
                                setState(
                                  () {},
                                );
                              },
                            ),
                          ],
                        ),
                        children: <Widget>[
                          Column(
                            children: _buildExpandableContent(i),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Container()
      ],
    );
  }

  getCombination(List<String> att, List<String> attId, int i) {
    for (int j = 0, l = finalAttList[i].length; j < l; j++) {
      List<String> a = [];
      List<String> aId = [];
      if (att.isNotEmpty) {
        a.addAll(att);
        aId.addAll(attId);
      }
      a.add(finalAttList[i][j].value!);
      aId.add(finalAttList[i][j].id!);
      if (i == max) {
        resultAttr.addAll(a);
        resultID.addAll(aId);
        Product_Varient model =
            Product_Varient(attr_name: a.join(","), id: aId.join(","));
        variationList.add(model);
      } else {
        getCombination(a, aId, i + 1);
      }
    }
  }

  _buildExpandableContent(int pos) {
    List<Widget> columnContent = [];

    columnContent.add(
      variantProductPrice(pos),
    );
    columnContent.add(
      variantProductSpecialPrice(pos),
    );

    columnContent.add(productType == 'variable_product' &&
            variantStockLevelType == "variable_level" &&
            _isStockSelected != null &&
            _isStockSelected == true
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              variableVariableSKU(pos),
              variantVariableTotalstock(pos),
              getPrimaryCommanText(
                  getTranslated(context, "Stock Status :")!, true),
              variantStockStatusSelect(pos)
            ],
          )
        : Container());

    columnContent.add(otherImages("variant", pos));

    columnContent.add(variantOtherImageShow(pos));
    return columnContent;
  }

  Widget variantProductPrice(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getPrimaryCommanText(getTranslated(context, "PRICE_LBL")!, true),
          Container(
            width: width * 0.4,
            height: height * 0.06,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              keyboardType: TextInputType.number,
              initialValue: variationList[pos].price ?? '',
              style: const TextStyle(
                color: black,
                fontWeight: FontWeight.normal,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                variationList[pos].price = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xfff5f5f5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffe6e6e6)),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget variantProductSpecialPrice(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getPrimaryCommanText(getTranslated(context, "Special Price")!, true),
          Container(
            width: width * 0.4,
            height: height * 0.06,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              keyboardType: TextInputType.number,
              initialValue: variationList[pos].disPrice ?? '',
              style: const TextStyle(
                color: black,
                fontWeight: FontWeight.normal,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                variationList[pos].disPrice = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xfff5f5f5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffe6e6e6)),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  addValAttribute(List<AttributeValueModel> selected,
      List<AttributeValueModel> searchRange, String attributeId) {
    showModalBottomSheet<List<AttributeValueModel>>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      enableDrag: true,
      context: context,
      builder: (context) {
        return SizedBox(
          height: 240,
          width: MediaQuery.of(context).size.width,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            getTranslated(context, "Select Attribute Value")!,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    mainAxisSpacing: 5.0,
                    crossAxisSpacing: 5.0),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return filterChipWidget(
                      chipName: searchRange[index],
                      selectedList: selected,
                      update: update,
                    );
                  },
                  childCount: searchRange.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  update() {
    setState(
      () {},
    );
  }

  addAttribute(int pos) {
    final result = attributesList
        .where((element) => element.name == _attrController[pos].text)
        .toList();
    final attributeId = result.isEmpty ? "" : result.first.id;
    return Card(
      color: const Color(0xfff5f5f5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10.0,
          bottom: 10,
          left: 15,
          right: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getPrimaryCommanText(
                    getTranslated(context, "Select Attribute")!, true),
                Checkbox(
                  value: variationBoolList[pos],
                  onChanged: (bool? value) {
                    setState(
                      () {
                        variationBoolList[pos] = value ?? false;
                      },
                    );
                  },
                )
              ],
            ),
            getCommanSizedBox(),
            TextFormField(
              textAlign: TextAlign.center,
              readOnly: true,
              onTap: () {
                attributeDialog(pos);
              },
              controller: _attrController[pos],
              keyboardType: TextInputType.text,
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.normal,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xfff6d6d5),
                hintText: getTranslated(context, "Select Attributes")!,
                hintStyle: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.normal,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            getCommanSizedBox(),
            getCommanSizedBox(),
            GestureDetector(
              onTap: () {
                final attributeValues = attributesValueList
                    .where((element) => element.attributeId == attributeId)
                    .toList();
                addValAttribute(selectedAttributeValues[attributeId]!,
                    attributeValues, attributeId!);
              },
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7.0),
                  color: const Color(0xfff6d6d5),
                ),
                constraints: const BoxConstraints(
                  minHeight: 50,
                ),
                child: (selectedAttributeValues[attributeId!] ?? []).isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Center(
                          child: Text(
                            getTranslated(context, "Add attribute value")!,
                            style: const TextStyle(
                              color: primary,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      )
                    : Wrap(
                        alignment: WrapAlignment.center,
                        direction: Axis.horizontal,
                        children: selectedAttributeValues[attributeId]!
                            .map(
                              (value) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: primary_app,
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      value.value!,
                                      style: const TextStyle(
                                        color: white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
            getCommanSizedBox(),
          ],
        ),
      ),
    );
  }

  variantStockStatusSelect(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      variationList[pos].stockStatus == '1'
                          ? getTranslated(context, "In Stock")!
                          : getTranslated(context, "Out Of Stock")!,
                    )
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          variantStockStatusDialog("variable", pos);
        },
      ),
    );
  }

  variantStockStatusDialog(String from, int pos) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Type")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  if (from == 'variable') {
                                    variationList[pos].stockStatus = "1";
                                  } else {
                                    stockStatus = '1';
                                  }
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "In Stock")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  if (from == 'variable') {
                                    variationList[pos].stockStatus = "0";
                                  } else {
                                    stockStatus = '0';
                                  }
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Out Of Stock")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  variantVariableTotalstock(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getPrimaryCommanText(getTranslated(context, "Total Stock")!, true),
          Container(
            width: width * 0.4,
            height: height * 0.06,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              keyboardType: TextInputType.number,
              initialValue: variationList[pos].stock ?? '',
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: variountProductTotalStockFocus,
              textInputAction: TextInputAction.next,
              onChanged: (String? value) {
                variationList[pos].stock = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xfff5f5f5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffe6e6e6)),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget variableVariableSKU(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getPrimaryCommanText(getTranslated(context, "SKU")!, true),
          Container(
            width: width * 0.4,
            height: height * 0.06,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context).requestFocus(variountProductSKUFocus);
              },
              initialValue: variationList[pos].sku ?? '',
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: variountProductSKUFocus,
              textInputAction: TextInputAction.next,
              onChanged: (String? value) {
                variationList[pos].sku = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xfff5f5f5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffe6e6e6)),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  stockStatusDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Type")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  simpleproductStockStatus = '1';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "In Stock")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  simpleproductStockStatus = '0';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Out Of Stock")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  productTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Type")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  variantProductVariableLevelSaveSettings =
                                      false;
                                  variantProductProductLevelSaveSettings =
                                      false;
                                  simpleProductSaveSettings = false;
                                  productType = 'simple_product';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, "Simple Product")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  //----reset----
                                  simpleProductPriceController.text = '';
                                  simpleProductSpecialPriceController.text = '';
                                  _isStockSelected = false;

                                  //--------------set
                                  variantProductVariableLevelSaveSettings =
                                      false;
                                  variantProductProductLevelSaveSettings =
                                      false;
                                  simpleProductSaveSettings = false;
                                  productType = 'variable_product';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(
                                          context, "Variable Product")!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//==============================================================================
//=========================== Variable Product Fields ==========================

// Choose Stock Management Type:

  variountProductStockManagementTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, "Select Stock Type")!,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  variantStockLevelType = 'product_level';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        getTranslated(
                                          context,
                                          "Product Level (Stock Will Be Managed Generally)",
                                        )!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  variantStockLevelType = 'variable_level';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        getTranslated(
                                          context,
                                          "Variable Level (Stock Will Be Managed Variant Wise)",
                                        )!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//==============================================================================
//=========================== Description ======================================

  getDescription() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: primary,
        ),
      ),
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8,
          right: 8,
        ),
        child: HtmlWidget(
          description ?? "",
          onErrorBuilder: (context, element, error) =>
              Text('$element error: $error'),
          onLoadingBuilder: (context, element, loadingProgress) =>
              const CircularProgressIndicator(),
          onTapUrl: (url) {
            launchUrl(
              Uri.parse(url),
            );
            return true;
          },
          renderMode: RenderMode.column,
          // set the default styling for text
          textStyle: const TextStyle(fontSize: 14),
          webView: true,
        ),
      ),
    );
  }

//==============================================================================
//=========================== Add Product API Call =============================

  Future<void> addProductAPI(List<String> attributesValuesIds) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var request = http.MultipartRequest("POST", addProductsApi);
        request.headers.addAll(headers);
        request.fields[SellerId] = CUR_USERID!;
        request.fields[ProInputName] = productName!;
        request.fields[ShortDescription] = sortDescription!;
        if (tags != null) request.fields[Tags] = tags!;
        if (taxId != null) request.fields[ProInputTax] = taxId!;
        if (indicatorValue != null) request.fields[Indicator] = indicatorValue!;
        if (madeIn != null) request.fields[MadeIn] = madeIn!;
        request.fields[TotalAllowedQuantity] = totalAllowQuantity!;
        request.fields[MinimumOrderQuantity] = minOrderQuantity!;
        request.fields[QuantityStepSize] = quantityStepSize!;
        if (warrantyPeriod != null) {
          request.fields[WarrantyPeriod] = warrantyPeriod!;
        }
        if (guaranteePeriod != null) {
          request.fields[GuaranteePeriod] = guaranteePeriod!;
        }
        request.fields[DeliverableType] = deliverabletypeValue!;
        request.fields[DeliverableZipcodes] = deliverableZipcodes ?? "null";
        request.fields[IsPricesInclusiveTax] = taxincludedinPrice!;
        request.fields[CodAllowed] = isCODAllow!;
        request.fields[IsReturnable] = isReturnable!;
        request.fields[IsCancelable] = isCancelable!;
        request.fields[ProInputImage] = productImage;

        if (tillwhichstatus != null) {
          request.fields[CancelableTill] = tillwhichstatus!;
        }
        if (otherPhotos.isNotEmpty) {
          request.fields[OtherImages] = otherPhotos.join(",");
        }
        if (selectedTypeOfVideo != null) {
          request.fields[VideoType] = selectedTypeOfVideo!;
        }
        if (videoUrl != null) request.fields[Video] = videoUrl!;
        if (uploadedVideoName != '') {
          request.fields[ProInputVideo] = uploadedVideoName;
        }
        if (description != null) {
          request.fields[ProInputDescription] = description ?? "";
        }
        request.fields[CategoryId] = selectedCatID!;
      if (selectedBrandName != null) { 
        request.fields['brand'] = selectedBrandName!;
          }  
       request.fields[ProductType] = productType!;
        request.fields[VariantStockLevelType] = variantStockLevelType!;
        request.fields[AttributeValues] = attributesValuesIds.join(",");

        if (productType == 'simple_product') {
          String? status;
          if (_isStockSelected == null) {
            status = null;
          } else {
            status = simpleproductStockStatus;
          }

          request.fields[SimpleProductStockStatus] = status ?? 'null';
          request.fields[SimplePrice] = simpleProductPriceController.text;
          request.fields[SimpleSpecialPrice] =
              simpleProductSpecialPriceController.text;
          if (_isStockSelected != null &&
              _isStockSelected == true &&
              simpleproductSKU != null) {
            request.fields[ProductSku] = simpleproductSKU!;
            request.fields[ProductTotalStock] = simpleproductTotalStock!;
            request.fields[VariantStockStatus] = "0";
          }
        } else if (productType == 'variable_product') {
          String val = '', price = '', sprice = '', images = '';
          List<List<String>> imagesList = [];
          for (int i = 0; i < variationList.length; i++) {
            if (val == '') {
              val = variationList[i].id!.replaceAll(',', ' ');
              price = variationList[i].price!;
              sprice = variationList[i].disPrice ?? ' ';
            } else {
              val = "$val,${variationList[i].id!.replaceAll(',', ' ')}";
              price = "$price,${variationList[i].price!}";
              sprice = "$sprice,${variationList[i].disPrice ?? ' '}";
            }

            if (variationList[i].imageRelativePath != null) {
              if (variationList[i].imageRelativePath!.isNotEmpty &&
                  images != '') {
                images =
                    '$images,${variationList[i].imageRelativePath!.join(",")}';
              } else if (variationList[i].imageRelativePath!.isNotEmpty &&
                  images == '') {
                images = variationList[i].imageRelativePath!.join(",");
              }

              List<String> subListofImage = images.split(',');
              images = "";

              for (int j = 0; j < subListofImage.length; j++) {
                subListofImage[j] = '"${subListofImage[j]}"';
              }
              imagesList.add(subListofImage);
            }
          }
          request.fields[VariantsIds] = val;
          request.fields[VariantPrice] = price;
          request.fields[VariantSpecialPrice] = sprice;
          request.fields[variant_images] = imagesList.toString();
          if (variantStockLevelType == 'product_level') {
            request.fields[SkuVariantType] = variountProductSKUController.text;
            request.fields[TotalStockVariantType] =
                variountProductTotalStock.text;
            request.fields[VariantStatus] = stockStatus;
          } else if (variantStockLevelType == 'variable_level') {
            String sku = '', totalStock = '', stkStatus = '';
            for (int i = 0; i < variationList.length; i++) {
              if (sku == '') {
                sku = variationList[i].sku!;
                totalStock = variationList[i].stock!;
                stkStatus = variationList[i].stockStatus!;
              } else {
                sku = "$sku,${variationList[i].sku!}";
                totalStock = "$totalStock,${variationList[i].stock!}";
                stkStatus = "$stkStatus,${variationList[i].stockStatus!}";
              }
            }
            request.fields[VariantSku] = sku;
            request.fields[VariantTotalStock] = totalStock;
            request.fields[VariantLevelStockStatus] = stkStatus;
          }
        }
        print("parameter");
        print(request.fields.toString());
        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var getdata = json.decode(responseString);
        bool error = getdata["error"];
        String msg = getdata['message'];
        if (!error) {
          await buttonController!.reverse();
          setsnackbar(msg, context);
          currentPage = 1;
          setState(() {});
        } else {
          await buttonController!.reverse();
          setsnackbar(msg, context);
        }
      } on TimeoutException catch (_) {
        setsnackbar(
          getTranslated(context, 'somethingMSg')!,
          context,
        );
      }
    } else if (mounted) {
      Future.delayed(const Duration(seconds: 2)).then(
        (_) async {
          await buttonController!.reverse();
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        },
      );
    }
  }

//==============================================================================
//=========================== Add Product Button ===============================

  resetProButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute<String>(
                builder: (context) => const AddProduct(),
              ),
            );
            setsnackbar(getTranslated(context, "Reset Successfully")!, context);
          },
          child: Container(
            height: 50,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: lightBlack2,
            ),
            child: Center(
              child: Text(
                getTranslated(context, "Reset All")!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

//==============================================================================
//=========================== Body Part ========================================

  getBodyPart() {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 25.0,
                  bottom: 20,
                  right: 20.0,
                  left: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    currentPage == 1 ? current_Page1() : Container(),
                    currentPage == 2 ? current_Page2() : Container(),
                    currentPage == 3 ? current_Page3() : Container(),
                    currentPage == 4 ? current_Page4() : Container(),
                    const SizedBox(
                      height: 60,
                    )
                    // resetProButton(),
                  ],
                ),
              ),
            ),
          ),
          getButtomBarButton(),
        ],
      ),
    );
  }

  getButtomBarButton() {
    return Positioned.directional(
      bottom: 0.0,
      textDirection: Directionality.of(context),
      child: Container(
        width: width,
        height: 60,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              currentPage != 1
                  ? Expanded(
                      child: InkWell(
                        onTap: () {
                          if (currentPage == 1) {
                          } else if (currentPage == 2) {
                            currentPage = 1;
                          } else if (currentPage == 3) {
                            currentPage = 2;
                          } else if (currentPage == 4) {
                            currentPage = 3;
                          }
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: lightWhite1,
                          ),
                          height: 56,
                          child: Center(
                            child: Text(
                              getTranslated(context, "Back")!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    if (currentPage == 1) {
                      if (productName == null) {
                        setsnackbar(
                          getTranslated(context, "Please select product Name")!,
                          context,
                        );
                      } else if (sortDescription == null) {
                        setsnackbar(
                          getTranslated(
                              context, "Please Add Sort Description")!,
                          context,
                        );
                      } else {
                        setState(() {
                          currentPage = 2;
                        });
                      }
                    } else if (currentPage == 2) {
                      if (totalAllowQuantity == null) {
                        setsnackbar(
                          getTranslated(
                              context, "Please Add Total Allowed Quantity")!,
                          context,
                        );
                      } else if (minOrderQuantity == null) {
                        setsnackbar(
                          getTranslated(
                              context, "Please Add minimam Order Quantity")!,
                          context,
                        );
                      } else if (quantityStepSize == null) {
                        setsnackbar(
                          getTranslated(
                              context, "Please Add Quantity Step Size")!,
                          context,
                        );
                      } else if (isCancelable == "1" &&
                          tillwhichstatus == null) {
                        setsnackbar(
                          getTranslated(
                              context, "Please Add Till Which Status")!,
                          context,
                        );
                      } else if (selectedCatID == null) {
                        setsnackbar(
                          getTranslated(context, "Please select category")!,
                          context,
                        );
                      } else {
                        setState(() {
                          currentPage = 3;
                        });
                      }
                    } else if (currentPage == 3) {
                      if (productImage == "") {
                        setsnackbar(
                          getTranslated(
                              context, "Please Add Product Main Image")!,
                          context,
                        );
                      } else if ((description == '' || description == null)) {
                        setsnackbar(
                          getTranslated(context, "Please Add Description")!,
                          context,
                        );
                      } else {
                        setState(() {
                          currentPage = 4;
                        });
                      }
                    } else if (currentPage == 4) {
                      validateAndSubmit();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: primary,
                    ),
                    height: 56,
                    child: Center(
                      child: Text(
                        currentPage != 4
                            ? getTranslated(context, "Next")!
                            : getTranslated(context, "Add Product")!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

//==============================================================================
//============================= UI Part ========================================

  current_Page1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getPrimaryCommanText(getTranslated(context, "PRODUCTNAME_LBL")!, false),
        getCommanSizedBox(),
        getCommanInputTextField(
          getTranslated(context, "PRODUCTHINT_TXT")!,
          1,
          0.06,
          1,
          2,
        ),
        getCommanSizedBox(),
        getPrimaryCommanText(
            getTranslated(context, "ShortDescription")!, false),
        getCommanSizedBox(),
        getCommanInputTextField(
          getTranslated(context, "Add Sort Detail of Product ...!")!,
          2,
          0.12,
          1,
          1,
        ),
        getCommanSizedBox(),
        Row(
          children: [
            getPrimaryCommanText(getTranslated(context, "Tags")!, false),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.loose,
              child: getSecondaryCommanText(
                getTranslated(
                    context, "(These tags help you in search result)")!,
              ),
            ),
          ],
        ),
        getCommanSizedBox(),
        getCommanInputTextField(
          getTranslated(context,
              "Type in some tags for example AC, Cooler, Flagship Smartphones, Mobiles, Sport etc..")!,
          3,
          0.06,
          1,
          2,
        ),
        getCommanSizedBox(),
        getPrimaryCommanText(getTranslated(context, "Select Tax")!, false),
        getCommanSizedBox(),
        getIconSelectionDesing(getTranslated(context, "Select Tax")!, 1),
        getCommanSizedBox(),
        getPrimaryCommanText(
            getTranslated(context, "Select Indicator")!, false),
        getCommanSizedBox(),
        getIconSelectionDesing(getTranslated(context, "Select Indicator")!, 2),
        getCommanSizedBox(),
        getPrimaryCommanText(getTranslated(context, "Made In")!, false),
        getCommanSizedBox(),
        getIconSelectionDesing(getTranslated(context, "Made In")!, 3),
        getCommanSizedBox(),
      ],
    );
  }

  current_Page2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Total Allowed Quantity")!, true),
            ),
            Expanded(
              flex: 3,
              child: getCommanInputTextField(
                " ",
                4,
                0.06,
                1,
                3,
              ),
            ),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Minimum Order Quantity")!, true),
            ),
            Expanded(
              flex: 3,
              child: getCommanInputTextField(
                " ",
                5,
                0.06,
                1,
                3,
              ),
            ),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Quantity Step Size")!, true),
            ),
            Expanded(
              flex: 3,
              child: getCommanInputTextField(
                " ",
                6,
                0.06,
                1,
                3,
              ),
            ),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Warranty Period")!, true),
            ),
            Expanded(
              flex: 3,
              child: getCommanInputTextField(
                " ",
                7,
                0.06,
                1,
                2,
              ),
            ),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Guarantee Period")!, true),
            ),
            Expanded(
              flex: 3,
              child: getCommanInputTextField(
                " ",
                8,
                0.06,
                1,
                2,
              ),
            ),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Deliverable Type")!, true),
            ),
            Expanded(
              flex: 3,
              child: getIconSelectionDesing(
                  getTranslated(context, "(ex, all, include)")!, 4),
            ),
          ],
        ),
        deliverabletypeValue == "2" || deliverabletypeValue == "3"
            ? getCommanSizedBox()
            : Container(),
        deliverabletypeValue == "2" || deliverabletypeValue == "3"
            ? getPrimaryCommanText(
                getTranslated(context, "Select ZipCode")!, false)
            : Container(),
        deliverabletypeValue == "2" || deliverabletypeValue == "3"
            ? getIconSelectionDesing(
                getTranslated(context, "not Selected Yet!(ex. 791572)")!, 6)
            : Container(),
        getCommanSizedBox(),
        getPrimaryCommanText(
            getTranslated(context, "selected category")!, false),
        getCommanSizedBox(),
        getIconSelectionDesing(
            getTranslated(
                context, "not Selected Yet!(ex. vegetable, Fashion)")!,
            5),
              getCommanSizedBox(),
        getPrimaryCommanText(
            "select Brand", false),
        getCommanSizedBox(),
        getIconSelectionDesing(
            "not Selected Yet!(ex. TaTa, Apple, MicroSoft)",
            13),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Is Product Returnable?")!, true),
            ),
            getCommanSwitch(1),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Is Product COD Allowed?")!, true),
            ),
            getCommanSwitch(2),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Tax included in price?")!, true),
            ),
            getCommanSwitch(3),
          ],
        ),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Is Product Cancelable?")!, true),
            ),
            getCommanSwitch(4),
          ],
        ),
        isCancelable == "1" ? getCommanSizedBox() : Container(),
        isCancelable == "1"
            ? getPrimaryCommanText(
                getTranslated(context, "Cancelable Till Which Status?")!, false)
            : Container(),
        isCancelable == "1" ? getCommanSizedBox() : Container(),
        isCancelable == "1"
            ? getIconSelectionDesing(
                getTranslated(context, "Not Selected Yet!(Ex. Receive)")!, 7)
            : Container(),
      ],
    );
  }

  current_Page3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Product Main Image")!, true),
            ),
            Expanded(
              flex: 2,
              child: getCommonButton(getTranslated(context, "Upload")!, 1),
            ),
          ],
        ),
        productImage != '' ? getCommanSizedBox() : Container(),
        productImage != '' ? getCommanSizedBox() : Container(),
        productImage != '' ? selectedMainImageShow() : Container(),
        getCommanSizedBox(),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText(
                  getTranslated(context, "Product Other Images")!, true),
            ),
            Expanded(
              flex: 2,
              child: getCommonButton(getTranslated(context, "Upload")!, 2),
            ),
          ],
        ),
        otherImageUrl.isNotEmpty ? getCommanSizedBox() : Container(),
        otherImageUrl.isNotEmpty ? getCommanSizedBox() : Container(),
        otherImageUrl.isNotEmpty ? uploadedOtherImageShow() : Container(),
        getCommanSizedBox(),
        getPrimaryCommanText(
            getTranslated(context, "Select Video Type")!, false),
        getCommanSizedBox(),
        getIconSelectionDesing(
            getTranslated(context, "not Selected Yet!(ex. Vimeo, Youtube)")!,
            8),
        getCommanSizedBox(),
        (selectedTypeOfVideo == 'vimeo' || selectedTypeOfVideo == 'youtube')
            ? getCommanInputTextField(
                selectedTypeOfVideo == 'vimeo'
                    ? getTranslated(
                        context,
                        "Paste Vimeo Video link / url ...!",
                      )!
                    : selectedTypeOfVideo == 'youtube'
                        ? getTranslated(
                            context,
                            "Paste Youtube Video link / url...!",
                          )!
                        : getTranslated(context, "Self Hosted")!,
                9,
                0.06,
                1,
                2,
              )
            : selectedTypeOfVideo == 'Self Hosted'
                ? Column(
                    children: [
                      videoUpload(),
                      selectedVideoShow(),
                    ],
                  )
                : Container(),
        getCommanSizedBox(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: getPrimaryCommanText("Product Description", true),
            ),
            Expanded(
              flex: 2,
              child: getCommonButton(
                  (description == "" || description == null)
                      ? getTranslated(context, "Add Description")!
                      : getTranslated(context, "Edit Description")!,
                  3),
            ),
          ],
        ),
        (description == "" || description == null)
            ? Container()
            : getCommanSizedBox(),
        (description == "" || description == null)
            ? Container()
            : getDescription(),
      ],
    );
  }

  current_Page4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        additionalInfo(),
      ],
    );
  }

// upload button :-

  getCommonButton(String title, int index) {
    return InkWell(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const Media(
                from: "main",
                type: "add",
              ),
            ),
          ).then(
            (value) => setState(
              () {},
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const Media(
                from: "other",
                pos: 0,
                type: "add",
              ),
            ),
          ).then(
            (value) => setState(
              () {},
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            CupertinoPageRoute<String>(
              builder: (context) => ProductDescription(description ?? ""),
            ),
          ).then((changed) {
            description = changed;
          });
        } else if (index == 4) {
          if (simpleProductPriceController.text.isEmpty) {
            setsnackbar(
              getTranslated(context, "Please enter product price")!,
              context,
            );
          } else if (simpleProductSpecialPriceController.text.isEmpty) {
            setState(
              () {
                simpleProductSaveSettings = true;
                setsnackbar(
                  getTranslated(context, "Setting saved successfully")!,
                  context,
                );
              },
            );
          } else if (int.parse(simpleproductPrice!) <
              int.parse(simpleproductSpecialPrice!)) {
            setsnackbar(
              getTranslated(
                  context, "Special price must be less than original price")!,
              context,
            );
          } else {
            setState(
              () {
                simpleProductSaveSettings = true;
                setsnackbar(
                  getTranslated(context, "Setting saved successfully")!,
                  context,
                );
              },
            );
          }
        } else if (index == 5) {
          if (_isStockSelected != null &&
              _isStockSelected == true &&
              (variountProductTotalStock.text.isEmpty || stockStatus.isEmpty)) {
            setsnackbar(
              getTranslated(context, "Please enter all details")!,
              context,
            );
          } else {
            setState(
              () {
                variantProductProductLevelSaveSettings = true;
                setsnackbar(
                    getTranslated(context, "Setting saved successfully")!,
                    context);
              },
            );
          }
        } else if (index == 6) {
          setState(
            () {
              variantProductVariableLevelSaveSettings = true;
              setsnackbar(
                getTranslated(context, "Setting saved successfully")!,
                context,
              );
            },
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: primary,
        ),
        height: 35,
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

// Comman Primary Text Field :-

  getPrimaryCommanText(String title, bool isMultipleLine) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        color: black,
      ),
      overflow: isMultipleLine ? TextOverflow.ellipsis : null,
      softWrap: true,
      maxLines: isMultipleLine ? 2 : 1,
    );
  }

// Comman Secondary Text Field :-

  getSecondaryCommanText(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.grey,
      ),
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
// get command sized Box

  getCommanSizedBox() {
    return const SizedBox(
      height: 10,
    );
  }
// Comman Input Text Field :-

  getCommanInputTextField(
    String title,
    int index,
    double heightvalue,
    double widthvalue,
    int textType,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: grey1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: grey2,
          width: 2,
        ),
      ),
      width: width * widthvalue,
      height: height * heightvalue,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8,
          right: 8,
        ),
        child: TextFormField(
          onFieldSubmitted: (v) {
            FocusScope.of(context).requestFocus(
              () {
                if (index == 1) {
                  return productFocus;
                } else if (index == 2) {
                  return sortDescriptionFocus;
                } else if (index == 3) {
                  return tagFocus;
                } else if (index == 4) {
                  return totalAllowFocus;
                } else if (index == 5) {
                  return minOrderFocus;
                } else if (index == 6) {
                  return quantityStepSizeFocus;
                } else if (index == 7) {
                  return warrantyPeriodFocus;
                } else if (index == 8) {
                  return guaranteePeriodFocus;
                } else if (index == 9) {
                  return vidioTypeFocus;
                } else if (index == 10) {
                  return simpleProductPriceFocus;
                } else if (index == 11) {
                  return simpleProductSpecialPriceFocus;
                } else if (index == 12) {
                  return simpleProductSKUFocus;
                } else if (index == 13) {
                  return simpleProductTotalStockFocus;
                } else if (index == 14) {
                  return variountProductSKUFocus;
                } else if (index == 15) {
                  return variountProductTotalStockFocus;
                }
              }(),
            );
          },
          focusNode: () {
            if (index == 1) {
              return productFocus;
            } else if (index == 2) {
              return sortDescriptionFocus;
            } else if (index == 3) {
              return tagFocus;
            } else if (index == 4) {
              return totalAllowFocus;
            } else if (index == 5) {
              return minOrderFocus;
            } else if (index == 6) {
              return quantityStepSizeFocus;
            } else if (index == 7) {
              return warrantyPeriodFocus;
            } else if (index == 8) {
              return guaranteePeriodFocus;
            } else if (index == 9) {
              return vidioTypeFocus;
            } else if (index == 10) {
              return simpleProductPriceFocus;
            } else if (index == 11) {
              return simpleProductSpecialPriceFocus;
            } else if (index == 12) {
              return simpleProductSKUFocus;
            } else if (index == 13) {
              return simpleProductTotalStockFocus;
            } else if (index == 14) {
              return variountProductSKUFocus;
            } else if (index == 15) {
              return variountProductTotalStockFocus;
            }
          }(),
          readOnly: false,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(
            color: black,
            fontWeight: FontWeight.normal,
          ),
          controller: () {
            if (index == 1) {
              return productNameControlller;
            } else if (index == 2) {
              return sortDescriptionControlller;
            } else if (index == 3) {
              return tagsControlller;
            } else if (index == 4) {
              return totalAllowController;
            } else if (index == 5) {
              return minOrderQuantityControlller;
            } else if (index == 6) {
              return quantityStepSizeControlller;
            } else if (index == 7) {
              return warrantyPeriodController;
            } else if (index == 8) {
              return guaranteePeriodController;
            } else if (index == 9) {
              return vidioTypeController;
            } else if (index == 10) {
              return simpleProductPriceController;
            } else if (index == 11) {
              return simpleProductSpecialPriceController;
            } else if (index == 12) {
              return simpleProductSKUController;
            } else if (index == 13) {
              return simpleProductTotalStock;
            } else if (index == 14) {
              return variountProductSKUController;
            } else if (index == 15) {
              return variountProductTotalStock;
            }
          }(),
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          keyboardType: textType == 1
              ? TextInputType.multiline
              : textType == 2
                  ? TextInputType.text
                  : TextInputType.number,
          onChanged: (value) {
            if (index == 1) {
              productName = value;
            } else if (index == 2) {
              sortDescription = value;
            } else if (index == 3) {
              tags = value;
            } else if (index == 4) {
              totalAllowQuantity = value;
            } else if (index == 5) {
              minOrderQuantity = value;
            } else if (index == 6) {
              quantityStepSize = value;
            } else if (index == 7) {
              warrantyPeriod = value;
            } else if (index == 8) {
              guaranteePeriod = value;
            } else if (index == 9) {
              videoUrl = value;
            } else if (index == 10) {
              simpleproductPrice = value;
            } else if (index == 11) {
              simpleproductSpecialPrice = value;
            } else if (index == 12) {
              simpleproductSKU = value;
            } else if (index == 13) {
              simpleproductTotalStock = value;
            } else if (index == 14) {
              variantproductSKU = value;
            } else if (index == 15) {
              variantproductTotalStock = value;
            }
          },
          validator: (val) => () {
            if (index == 1) {
              validateProduct(val, context);
            } else if (index == 2) {
              sortdescriptionvalidate(val, context);
            } else if (index == 4) {
              validateThisFieldRequered(val, context);
            } else if (index == 5) {
              validateThisFieldRequered(val, context);
            } else if (index == 6) {
              validateThisFieldRequered(val, context);
            }
          }(),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            hintText: title,
          ),
          minLines: null,
          maxLines: index == 2 ? null : 1,
          expands: index == 2 ? true : false,
        ),
      ),
    );
  }

// Comman Input Text Field :-     .
  getIconSelectionDesing(
    String title,
    int index,
  ) {
    return InkWell(
      onTap: () {
        if (index == 1) {
          taxesDialog();
        } else if (index == 2) {
          indicatorDialog();
        } else if (index == 3) {
          cityDialog();
        } else if (index == 4) {
          deliverableZipcodes = null;
          deliverableTypeDialog();
        } else if (index == 5) {
          categorySelectButtomSheet();
        } else if (index == 6) {
          zipcodeDialog();
        } else if (index == 7) {
          tillWhichStatusDialog();
        } else if (index == 8) {
          videoselectionDialog();
        } else if (index == 9) {
          FocusScope.of(context).requestFocus(FocusNode());
          productTypeDialog();
        } else if (index == 10) {
          FocusScope.of(context).requestFocus(FocusNode());
          stockStatusDialog();
        } else if (index == 11) {
          variountProductStockManagementTypeDialog();
        } else if (index == 12) {
          variantStockStatusDialog("product", 0);
        } else if (index == 13) {
          brandSelectButtomSheet();
        }


      },
      child: Container(
        decoration: BoxDecoration(
          color: grey1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: grey2,
            width: 2,
          ),
        ),
        width: width,
        height: height * 0.06,
        child: Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 9,
                  child: getSecondaryCommanText(
                    () {
                      if (index == 1) {
                        if (selectedTaxID != null) {
                          return "${taxesList[selectedTaxID!].title!} ${taxesList[selectedTaxID!].percentage!}%";
                        }
                        return title;
                      } else if (index == 2) {
                        if (indicatorValue == '0') {
                          return getTranslated(context, "None")!;
                        } else if (indicatorValue == '1') {
                          return getTranslated(context, "Veg")!;
                        } else if (indicatorValue == '2') {
                          return getTranslated(context, "Non-Veg")!;
                        }
                        return title;
                      } else if (index == 3) {
                        if (madeIn != null) {
                          return "${getTranslated(context, "Made In")!} ${madeIn!}";
                        }
                        return title;
                      } else if (index == 4) {
                        if (deliverabletypeValue == '0') {
                          return getTranslated(context, "None")!;
                        } else if (deliverabletypeValue == '1') {
                          return getTranslated(context, "All")!;
                        } else if (deliverabletypeValue == '2') {
                          return getTranslated(context, "Include")!;
                        } else if (deliverabletypeValue == '3') {
                          return getTranslated(context, "Exclude")!;
                        }
                      } else if (index == 5) {
                        if (selectedCatName != null) {
                          return selectedCatName!;
                        }
                      } else if (index == 6) {
                        if (deliverableZipcodes != null) {
                          return deliverableZipcodes!;
                        }
                      } else if (index == 7) {
                        if (tillwhichstatus == 'received') {
                          return getTranslated(context, "RECEIVED_LBL")!;
                        } else if (tillwhichstatus == 'processed') {
                          return getTranslated(context, "PROCESSED_LBL")!;
                        } else if (tillwhichstatus == 'shipped') {
                          return getTranslated(context, "SHIPED_LBL")!;
                        }
                      } else if (index == 8) {
                        if (selectedTypeOfVideo == 'vimeo') {
                          return getTranslated(context, "Vimeo")!;
                        } else if (selectedTypeOfVideo == 'youtube') {
                          return getTranslated(context, "Youtube")!;
                        } else if (selectedTypeOfVideo == 'Self Hosted') {
                          return "Self Hosted";
                        }
                      } else if (index == 9) {
                        if (productType == 'simple_product') {
                          return getTranslated(context, "Simple Product")!;
                        } else if (productType == 'variable_product') {
                          return getTranslated(context, "Variable Product")!;
                        }
                      } else if (index == 10) {
                        if (simpleproductStockStatus == '1') {
                          return getTranslated(context, "In Stock")!;
                        } else if (simpleproductStockStatus != null) {
                          return getTranslated(context, "Out Of Stock")!;
                        }
                      } else if (index == 11) {
                        if (variantStockLevelType == 'product_level') {
                          return getTranslated(
                            context,
                            "Product Level (Stock Will Be Managed Generally)",
                          )!;
                        } else if (variantStockLevelType != null) {
                          return getTranslated(
                            context,
                            "Variable Level (Stock Will Be Managed Variant Wise)",
                          )!;
                        }
                      } else if (index == 12) {
                        if (stockStatus == '1') {
                          return getTranslated(context, "In Stock")!;
                        } else if (stockStatus != null) {
                          return getTranslated(context, "Out Of Stock")!;
                        }
                      } else if (index == 13) {
                        if (selectedBrandName != null) {
                          return selectedBrandName!;
                        }
                      }
                      return title;
                    }(),
                  ),
                ),
                const Expanded(
                    flex: 1, child: Icon(Icons.arrow_drop_down_outlined)),
              ],
            )),
      ),
    );
  }

// Get Comman Switch :-     .

  getCommanSwitch(int index) {
    return Switch(
      onChanged: (value) {
        if (index == 1) {
          isreturnable = value;
          if (value) {
            isReturnable = "1";
          } else {
            isReturnable = "0";
          }
        } else if (index == 2) {
          isCODallow = value;
          if (value) {
            isCODAllow = "1";
          } else {
            isCODAllow = "0";
          }
        } else if (index == 3) {
          taxincludedInPrice = value;
          if (value) {
            taxincludedinPrice = "1";
          } else {
            taxincludedinPrice = "0";
          }
        } else if (index == 4) {
          iscancelable = value;
          if (value) {
            isCancelable = "1";
          } else {
            isCancelable = "0";
          }
        }
        setState(() {});
      },
      value: () {
        if (index == 1) {
          return isreturnable;
        } else if (index == 2) {
          return isCODallow;
        } else if (index == 3) {
          return taxincludedInPrice;
        } else if (index == 4) {
          return iscancelable;
        }
        return true;
      }(),
    );
  }

//==============================================================================
  void validateAndSubmit() async {
    List<String> attributeIds = [];
    List<String> attributesValuesIds = [];

    for (var i = 0; i < variationBoolList.length; i++) {
      if (variationBoolList[i]) {
        final attributes = attributesList
            .where((element) => element.name == _attrController[i].text)
            .toList();
        if (attributes.isNotEmpty) {
          attributeIds.add(attributes.first.id!);
        }
      }
    }
    for (var key in attributeIds) {
      for (var element in selectedAttributeValues[key]!) {
        attributesValuesIds.add(element.id!);
      }
    }
    if (validateAndSave()) {
      _playAnimation();
      addProductAPI(attributesValuesIds);
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      if (productType == null) {
        setsnackbar(
          getTranslated(context, "Please select product type")!,
          context,
        );
        return false;
      } else if (description == '' && description == null) {
        setsnackbar(
          "Please Add Description",
          context,
        );
        return false;
      } else if (productImage == '' && mainImageProductImage == "") {
        setsnackbar(
          getTranslated(context, "Please Add product image")!,
          context,
        );
        return false;
      } else if (selectedCatID == null) {
        setsnackbar(
          getTranslated(context, "Please select category")!,
          context,
        );
        return false;
      } else if (selectedTypeOfVideo != null && videoUrl == null) {
        setsnackbar(
          getTranslated(context, "Please enter video url")!,
          context,
        );
        return false;
      } else if (productType == 'simple_product') {
        if (simpleProductPriceController.text.isEmpty) {
          setsnackbar(
            getTranslated(context, "Please enter product price")!,
            context,
          );
          return false;
        } else if (simpleProductPriceController.text.isNotEmpty &&
            simpleProductSpecialPriceController.text.isNotEmpty &&
            double.parse(simpleProductSpecialPriceController.text) >
                double.parse(simpleProductPriceController.text)) {
          setsnackbar(
            getTranslated(context, "Special price can not greater than price")!,
            context,
          );
          return false;
        } else if (_isStockSelected != null && _isStockSelected == true) {
          if (simpleproductSKU == null || simpleproductTotalStock == null) {
            setsnackbar(
              getTranslated(context, "Please enter stock details")!,
              context,
            );
            return false;
          }
          return true;
        }
        return true;
      } else if (productType == 'variable_product') {
        for (int i = 0; i < variationList.length; i++) {
          if (variationList[i].price == null ||
              variationList[i].price!.isEmpty) {
            setsnackbar(
              getTranslated(context, "Please enter price details")!,
              context,
            );
            return false;
          }
        }
        if (_isStockSelected != null && _isStockSelected == true) {
          if (variantStockLevelType == "product_level" &&
              (variantproductSKU == null || variantproductTotalStock == null)) {
            setsnackbar(
              getTranslated(context, "Please enter stock details")!,
              context,
            );
            return false;
          }

          if (variantStockLevelType == "variable_level") {
            for (int i = 0; i < variationList.length; i++) {
              if (variationList[i].sku == null ||
                  variationList[i].sku!.isEmpty ||
                  variationList[i].stock == null ||
                  variationList[i].stock!.isEmpty) {
                setsnackbar(
                  getTranslated(context, "Please enter stock details")!,
                  context,
                );
                return false;
              }
            }
            return true;
          }
          return true;
        }
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: white,
        leading: Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(10),
              decoration: shadow(),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => Navigator.of(context).pop(),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: black,
                    size: 25,
                  ),
                ),
              ),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              getTranslated(context, "Add New Product")!,
              style: const TextStyle(
                color: black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: width * 0.1),
            Text(
              getTranslated(context, "Step")! +
                  " $currentPage " +
                  getTranslated(context, "of")! +
                  " 4",
              style: const TextStyle(
                color: grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),

      // getAppBar(
      //   getTranslated(context, "Add New Product")!,
      //   context,
      // ),
      body: getBodyPart(),
    );
  }
}
