import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/color.dart';
import '../Model/FAQModel/Faqs_Model.dart';
import '../Model/ProductModel/Product.dart';
import 'home.dart';

class AddFAQs extends StatefulWidget {
  final String? id;
  final Product? model;
  const AddFAQs(this.id, this.model, {Key? key}) : super(key: key);
  @override
  _AddFAQsState createState() => _AddFAQsState();
}

class _AddFAQsState extends State<AddFAQs> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool scrollLoadmore = true, scrollGettingData = false, scrollNodata = false;
  int scrollOffset = 0;
  List<FaqsModel> tagList = [];
  List<FaqsModel> tempList = [];
  List<TextEditingController> listController = [];
  List<FaqsModel> selectedList = [];
  ScrollController? scrollController;
  TextEditingController mobilenumberController = TextEditingController();
  TextEditingController answerController = TextEditingController();
  FocusNode? tagsController = FocusNode();
  FocusNode? ansFocus = FocusNode();
  String? tagvalue;
  String? ansValue;
  int perPageLoad = 10;
  @override
  void initState() {
    super.initState();
    scrollOffset = 0;
    getTags();

    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    scrollController = ScrollController(keepScrollOffset: true);
    scrollController!.addListener(_transactionscrollListener);

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

  _transactionscrollListener() {
    if (scrollController!.offset >=
            scrollController!.position.maxScrollExtent &&
        !scrollController!.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            scrollLoadmore = true;
            getTags();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(widget.model!.name ?? "", context),
      body: _isNetworkAvail ? _showContent() : noInternet(context),
    );
  }

  _showContent() {
    return scrollNodata
        ? Column(
            children: [
              uploadTags(),
              getNoItem(context),
            ],
          )
        : NotificationListener<ScrollNotification>(
            child: Column(
              children: [
                uploadTags(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    shrinkWrap: true,
                    padding: const EdgeInsetsDirectional.only(
                      bottom: 5,
                      start: 10,
                      end: 10,
                    ),
                    itemCount: tagList.length,
                    itemBuilder: (context, index) {
                      FaqsModel? item;

                      item = tagList.isEmpty ? null : tagList[index];

                      return item == null ? Container() : getMediaItem(index);
                    },
                  ),
                ),
                scrollGettingData
                    ? const Padding(
                        padding: EdgeInsetsDirectional.only(
                          top: 5,
                          bottom: 5,
                        ),
                        child: CircularProgressIndicator(),
                      )
                    : Container(),
              ],
            ),
          );
  }

  Future<void> addTagAPI() async {
    // CUR_USERID = await getPrefrence(Id);
    var parameter = {
      SellerId: CUR_USERID,
      ProductId: widget.id,
      QUESTION: tagvalue,
    };
    if (ansValue != "") {
      parameter[ANSWER] = ansValue;
    }
    print("parameter");
    apiBaseHelper.postAPICall(addProductFaqsApi, parameter).then(
      (getdata) async {
        print(getdata);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          setsnackbar(msg!, context);
          tagvalue = null;
          ansValue = null;
          mobilenumberController.text = "";
          answerController.text = "";
          setState(() {});
        } else {
          setsnackbar(msg!, context);
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

  uploadTags() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10,
        bottom: 10,
        start: 10,
        end: 10,
      ),
      child: Card(
        elevation: 10,
        child: InkWell(
          child: Column(
            children: [
              const SizedBox(
                height: 25,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  onFieldSubmitted: (v) {
                    FocusScope.of(context).requestFocus(tagsController);
                  },
                  controller: mobilenumberController,
                  decoration: InputDecoration(
                    counterStyle: const TextStyle(color: white, fontSize: 0),
                    hintText: getTranslated(context, "Enter New Question")!,
                    icon: const Icon(Icons.live_help_outlined),
                    iconColor: primary,
                    labelStyle: const TextStyle(
                      color: black,
                      fontSize: 17.0,
                    ),
                    hintStyle: const TextStyle(
                      color: black,
                      fontSize: 17.0,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  keyboardType: TextInputType.text,
                  focusNode: tagsController,
                  onSaved: (String? value) {
                    tagvalue = value;
                  },
                  onChanged: (String? value) {
                    tagvalue = value;
                  },
                  style: const TextStyle(
                    color: black,
                    fontSize: 18.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  onFieldSubmitted: (v) {
                    FocusScope.of(context).requestFocus(ansFocus);
                  },
                  controller: answerController,
                  decoration: InputDecoration(
                    counterStyle: TextStyle(color: white, fontSize: 0),
                    hintText:
                        getTranslated(context, "Enter Your Answer (Optional)")!,
                    icon: Icon(Icons.edit_note),
                    iconColor: primary,
                    labelStyle: TextStyle(
                      color: black,
                      fontSize: 17.0,
                    ),
                    hintStyle: TextStyle(
                      color: black,
                      fontSize: 17.0,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  keyboardType: TextInputType.text,
                  focusNode: ansFocus,
                  onSaved: (String? value) {
                    ansValue = value;
                  },
                  onChanged: (String? value) {
                    ansValue = value;
                  },
                  style: const TextStyle(
                    color: black,
                    fontSize: 18.0,
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              InkWell(
                onTap: () {
                  tagList.clear();
                  scrollLoadmore = true;
                  addTagAPI();
                  Future.delayed(const Duration(seconds: 2)).then(
                    (_) async {
                      scrollLoadmore = true;
                      scrollOffset = 0;
                      getTags();
                      setState(
                        () {},
                      );
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  width: 120,
                  height: 40,
                  child: Center(
                    child: Text(
                      getTranslated(context, "Add Question")!,
                      style: TextStyle(
                        color: white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 35,
              ),
            ],
          ),
        ),
      ),
    );
  }

  getAppBar(String title, BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: white,
      elevation: 1,
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
                  Icons.keyboard_arrow_left,
                  color: primary,
                  size: 30,
                ),
              ),
            ),
          );
        },
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: primary,
        ),
      ),
    );
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, "NO_INTERNET")!,
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
                          builder: (BuildContext context) => super.widget,
                        ),
                      ).then(
                        (value) {
                          setState(
                            () {},
                          );
                        },
                      );
                    } else {
                      await buttonController!.reverse();
                      if (mounted) {
                        setState(
                          () {},
                        );
                      }
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

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> getTags() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (scrollLoadmore) {
        if (mounted) {
          setState(
            () {
              scrollLoadmore = false;
              scrollGettingData = true;
              if (scrollOffset == 0) {
                listController = [];
                tagList = [];
              }
            },
          );
        }
        try {
          var parameter = {
            SellerId: CUR_USERID,
            ProductId: widget.id,
            LIMIT: perPageLoad.toString(),
            OFFSET: scrollOffset.toString(),
          };

          apiBaseHelper.postAPICall(getProductFaqsApi, parameter).then(
            (getdata) async {
              bool error = getdata["error"];
              String? msg = getdata["message"];
              scrollGettingData = false;
              if (scrollOffset == 0) scrollNodata = error;

              if (!error) {
                tempList.clear();
                var data = getdata["data"];
                if (data.length != 0) {
                  tempList = (data as List)
                      .map(
                        (data) => FaqsModel.fromJson(data),
                      )
                      .toList();

                  tagList.addAll(tempList);
                  for (var tag in tagList) {
                    listController
                        .add(TextEditingController(text: tag.answer!));
                  }
                  scrollLoadmore = true;
                  scrollOffset = scrollOffset + perPageLoad;
                } else {
                  scrollLoadmore = false;
                }
              } else {
                setsnackbar(msg!, context);
                scrollLoadmore = false;
              }
              if (mounted) {
                setState(
                  () {
                    scrollLoadmore = false;
                  },
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
        } on TimeoutException catch (_) {
          setsnackbar(
            getTranslated(context, "somethingMSg")!,
            context,
          );
          setState(
            () {
              scrollLoadmore = false;
            },
          );
        }
      }
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
            scrollLoadmore = false;
          },
        );
      }
    }
  }

  Future<void> deleteTagsAPI(String? id) async {
    CUR_USERID = await getPrefrence(Id);
    var parameter = {
      SellerId: CUR_USERID,
      Id: id,
    };
    apiBaseHelper.postAPICall(deleteProductFaqApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          setsnackbar(msg!, context);
          tagList.clear();
          scrollLoadmore = true;
        } else {
          setsnackbar(msg!, context);
        }
      },
      onError: (error) {
        setsnackbar(error.toString(), context);
      },
    );
  }

  Future<void> editProductFaqAPI(String? id, String answer) async {
    CUR_USERID = await getPrefrence(Id);
    var parameter = {
      SellerId: CUR_USERID,
      Id: id,
      ANSWER: answer,
    };
    apiBaseHelper.postAPICall(editProductFaqApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          setsnackbar(msg!, context);
          tagList.clear();
          scrollLoadmore = true;
        } else {
          setsnackbar(msg!, context);
        }
      },
      onError: (error) {
        setsnackbar(error.toString(), context);
      },
    );
  }

  getMediaItem(int index) {
    return Card(
      child: ExpansionTile(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(right: 15.0),
                  child: Icon(
                    Icons.radio_button_checked_outlined,
                    color: primary,
                  ),
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  tagList[index].question!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () {
                    deleteTagsAPI(tagList[index].id);
                    Future.delayed(const Duration(seconds: 2)).then(
                      (_) async {
                        scrollLoadmore = true;
                        scrollOffset = 0;
                        getTags();
                        setState(
                          () {},
                        );
                      },
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.delete,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              //        top: 8.0,
              right: 20,
              left: 20,
              bottom: 20,
            ),
            child: Column(
              children: [
                tagList[index].answer!.isNotEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 1, child: Text("=> ")),
                          Expanded(
                            flex: 8,
                            child: Text(
                              tagList[index].answer!,
                              style: const TextStyle(),
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(getTranslated(context, "No Answer Yet..!")!),
                Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      padding: const EdgeInsets.only(
                        top: 5.0,
                      ),
                      child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: listController[index],
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                          color: fontColor,
                          fontWeight: FontWeight.normal,
                        ),
                        onChanged: (String? value) {},
                        textInputAction: TextInputAction.next,
                        validator: (val) => validateMob(val!, context),
                        onSaved: (String? value) {},
                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide: const BorderSide(color: primary),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          hintText: tagList[index].answer!.isNotEmpty
                              ? getTranslated(context, "Edit Your Answer")
                              : getTranslated(context, "Enter Your Answer"),
                          hintStyle:
                              Theme.of(context).textTheme.subtitle2!.copyWith(
                                    color: lightBlack2,
                                    fontWeight: FontWeight.normal,
                                  ),
                          filled: true,
                          fillColor: white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            maxHeight: 20,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: const BorderSide(color: lightBlack2),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (listController[index].text.isEmpty) {
                          setsnackbar(
                              getTranslated(context, "Please Add Your Answer")!,
                              context);
                        } else {
                          editProductFaqAPI(
                              tagList[index].id, listController[index].text);
                          tagList.clear();
                          scrollLoadmore = true;
                          Future.delayed(const Duration(seconds: 2)).then(
                            (_) async {
                              scrollLoadmore = true;
                              scrollOffset = 0;
                              getTags();
                              setState(
                                () {},
                              );
                            },
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          width: 120,
                          height: 40,
                          child: Center(
                            child: Text(
                              getTranslated(context, "Update")!,
                              style: const TextStyle(
                                color: white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
