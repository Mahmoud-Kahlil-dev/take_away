import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:take_away/data/dialoge_options.dart';
import 'package:take_away/layout/admin_cubit/states.dart';
import 'package:take_away/model/drinks_model.dart';
import 'package:take_away/model/order_model.dart';
import 'package:take_away/model/user_model.dart';
import 'package:take_away/modules/admin_modules/deinks_menu/cold_drinks_admin_screen.dart';
import 'package:take_away/modules/admin_modules/deinks_menu/hot_drinks_admin_screen.dart';
import 'package:take_away/modules/admin_modules/done_orders.dart';
import 'package:take_away/modules/admin_modules/new_orders.dart';
import 'package:take_away/shared/components/constance.dart';
import 'package:take_away/shared/network/local/cache_helper.dart';
import 'dart:io';

class AdminCubit extends Cubit<AdminStates> {
  AdminCubit() : super(AdminInitialState());

  static AdminCubit get(context) => BlocProvider.of(context);

  UserModel?
      userModel; // ==> my json model that i use to receive data from Firestore

  void getUserData() async {
    uId = CacheHelper.getData(key: 'uId') ?? CacheHelper.getData(key: 'uId');
    emit(LoadingGetUserDataState());
    await FirebaseFirestore.instance
        .collection('users') // ==> my Firestore collection
        .doc(uId)
        .get()
        .then((value) async {
      userModel = UserModel.fromJson(value.data()!);

      emit(SuccessGetUserDataState());
    }).catchError((error) {
      print('Error is ${error.toString()}');
      emit(ErrorGetUserDataState());
    });
  }

  int mainCurrentIndex = 0;

  void mainChangeIndex(int index) {
    mainCurrentIndex = index;

    emit(AdminChangeBottomNavState());
  }

  List<Widget> mainBottomScreen = const [
    NewOrders(),
    DoneOrders(),
  ];

  List<String> mainBottomScreenTitle = [
    'أوردرات جديدة',
    'أوردرات إتسلمت',
  ];

  int menuCurrentIndex = 0;

  void menuChangeIndex(int index) {
    menuCurrentIndex = index;

    emit(AdminChangeBottomNavState());
  }

  List<Widget> menuBottomScreen = const [
    HotDrinksAdminScreen(),
    ColdDrinksAdminScreen(),
  ];

  var profilePicker = ImagePicker();
  File? profileImage;

  void getProfileImageFromGallery() async {
    emit(LoadingProfileImagePickedState());
    final pickedFile =
        await profilePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      profileImage = File(pickedFile.path);
      uploadProfileImage();
      emit(SuccessProfileImagePickedState());
    } else {
      emit(ErrorProfileImagePickedState());
    }
  }

  void getProfileImageFromCamera() async {
    final pickedFile =
        await profilePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      profileImage = File(pickedFile.path);
      uploadProfileImage();
      emit(SuccessProfileImagePickedState());
    } else {
      emit(ErrorProfileImagePickedState());
    }
  }

  void uploadProfileImage() {
    userModel!.image != ''
        ? deleteProfileImage()
        : emit(LoadingProfileImagePickedState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child('users/${Uri.file(profileImage!.path).pathSegments.last}')
        .putFile(profileImage!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        updateProfileImage(imageUrl: value);
        emit(SuccessUploadProfileImageState());
      }).catchError((e) {
        emit(ErrorUploadProfileImageState());
      });
    }).catchError((e) {
      emit(ErrorUploadProfileImageState());
    });
  }

  void updateProfileImage({required String imageUrl}) {
    UserModel model = UserModel(
      admin: true,
      address: userModel!.address,
      uId: userModel!.uId,
      email: userModel!.email,
      phone: userModel!.phone,
      name: userModel!.name,
      image: imageUrl,
      hasProfileImage: true,
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .update(model.toMap())
        .then((value) {
      getUserData();
    }).catchError((e) {
      print('Error is ${e.toString()}');
      emit(ErrorUpdateUserDataState());
    });
  }

  void deleteProfileImage() async {
    await firebase_storage.FirebaseStorage.instance
        .refFromURL(userModel!.image!)
        .delete();
    UserModel model = UserModel(
      admin: true,
      address: userModel!.address,
      uId: userModel!.uId,
      email: userModel!.email,
      phone: userModel!.phone,
      name: userModel!.name,
      image: '',
      hasProfileImage: false,
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(userModel!.uId)
        .update(model.toMap())
        .then((value) {
      getUserData();
    }).catchError((e) {
      print('Error is ${e.toString()}');
      emit(ErrorUpdateUserDataState());
    });
  }

  List<DrinksModel> hotDrinksMenu = [];
  List<DrinksModel> coldDrinksMenu = [];
  DrinksModel? drinksModel;

  void getHotDrinksData() async {
    emit(LoadingGetDrinksDataState());

    await FirebaseFirestore.instance
        .collection('hotDrinksMenu')
        .snapshots()
        .listen((event) {
      hotDrinksMenu = [];
      for (var element in event.docs) {
        hotDrinksMenu.add(DrinksModel.fromJson(element.data()));
      }
      emit(SuccessGetDrinksDataState());
    });

    // await FirebaseFirestore.instance
    //     .collection('hotDrinksMenu')
    //     .get()
    //     .then((value) async {
    //   value.docs.forEach((element) {
    //     hotDrinksMenu = [];
    //      element.reference.snapshots().listen((event) {
    //       drinkId.add(element.id);
    //       hotDrinksMenu.add(DrinksModel.fromJson(element.data()));
    //     });
    //   });
    //   emit(SuccessGetDrinksDataState());
    // }).catchError((error) {
    //   print('Error is ${error.toString()}');
    //   emit(ErrorGetDrinksDataState());
    // });
  }

  void addNewHotDrink({
    required String drinkName,
    required String drinkImage,
    required int price,
  }) async {
    emit(LoadingAddDrinkState());
    DrinksModel model = DrinksModel(
      price: price,
      id: dId,
      drinkName: drinkName,
      drinkImage: drinkImage,
    );
    await FirebaseFirestore.instance
        .collection('hotDrinksMenu')
        .doc('${model.id}')
        .set(model.toMap())
        .then((value) {
      CacheHelper.saveData(key: 'dId', value: ++dId);
      drinkImageUrl = '';
      getHotDrinksData();
      emit(SuccessAddDrinkState());
    }).catchError((error) {
      emit(ErrorAddDrinkState());
      print('Error is ${error.toString()}');
    });
  }

  void updateHotDrinkData({
    required String imageUrl,
    required String drinkName,
    required int price,
    required int id,
  }) {
    DrinksModel model = DrinksModel(
      price: price,
      id: id,
      drinkName: drinkName,
      drinkImage: imageUrl,
    );
    FirebaseFirestore.instance
        .collection('hotDrinksMenu')
        .doc('${model.id}')
        .update(model.toMap())
        .then((value) {
      getHotDrinksData();
    }).catchError((e) {
      print('Error is ${e.toString()}');
      emit(ErrorUpdateDrinkDataState());
    });
  }

  void deleteHotDrink({
    required int id,
  }) {
    FirebaseFirestore.instance
        .collection('hotDrinksMenu')
        .doc('$id')
        .delete()
        .then((value) {
      getHotDrinksData();
    }).catchError((e) {
      print('Error is ${e.toString()}');
      emit(ErrorUpdateDrinkDataState());
    });
  }

  void getColdDrinksData() async {
    emit(LoadingGetDrinksDataState());

    await FirebaseFirestore.instance
        .collection('coldDrinksMenu')
        .snapshots()
        .listen((event) {
      coldDrinksMenu = [];
      for (var element in event.docs) {
        coldDrinksMenu.add(DrinksModel.fromJson(element.data()));
      }
      emit(SuccessGetDrinksDataState());
    });
  }

  void addNewColdDrink({
    required String drinkName,
    required String drinkImage,
    required int price,
  }) async {
    emit(LoadingAddDrinkState());
    DrinksModel model = DrinksModel(
      price: price,
      id: dId,
      drinkName: drinkName,
      drinkImage: drinkImage,
    );
    await FirebaseFirestore.instance
        .collection('coldDrinksMenu')
        .doc('${model.id}')
        .set(model.toMap())
        .then((value) {
      CacheHelper.saveData(key: 'dId', value: ++dId);
      drinkImageUrl = '';
      getColdDrinksData();
      emit(SuccessAddDrinkState());
    }).catchError((error) {
      emit(ErrorAddDrinkState());
      print('Error is ${error.toString()}');
    });
  }

  void updateColdDrinkData({
    required String imageUrl,
    required String drinkName,
    required int price,
    required int id,
  }) {
    DrinksModel model = DrinksModel(
      price: price,
      id: id,
      drinkName: drinkName,
      drinkImage: imageUrl,
    );
    FirebaseFirestore.instance
        .collection('coldDrinksMenu')
        .doc('${model.id}')
        .update(model.toMap())
        .then((value) {
      getColdDrinksData();
    }).catchError((e) {
      print('Error is ${e.toString()}');
      emit(ErrorUpdateDrinkDataState());
    });
  }

  void deleteColdDrink({
    required int id,
  }) {
    FirebaseFirestore.instance
        .collection('coldDrinksMenu')
        .doc('$id')
        .delete()
        .then((value) {
      getHotDrinksData();
    }).catchError((e) {
      print('Error is ${e.toString()}');
      emit(ErrorUpdateDrinkDataState());
    });
  }

  var drinkImagePicker = ImagePicker();
  File? drinkImage;
  String? drinkImageUrl = '';

  void getDrinkImageFromGallery() async {
    emit(LoadingDrinkImagePickedState());
    final pickedFile =
        await drinkImagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      drinkImage = File(pickedFile.path);
      uploadDrinkImage();
      emit(SuccessDrinkImagePickedState());
    } else {
      emit(ErrorDrinkImagePickedState());
    }
  }

  void getDrinkImageFromCamera() async {
    emit(LoadingDrinkImagePickedState());
    final pickedFile =
        await drinkImagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      drinkImage = File(pickedFile.path);
      uploadDrinkImage();
      emit(SuccessDrinkImagePickedState());
    } else {
      emit(ErrorDrinkImagePickedState());
    }
  }

  void uploadDrinkImage() {
    emit(LoadingDrinkImagePickedState());
    firebase_storage.FirebaseStorage.instance
        .ref()
        .child('DrinksMenu/${Uri.file(drinkImage!.path).pathSegments.last}')
        .putFile(drinkImage!)
        .then((value) {
      value.ref.getDownloadURL().then((value) {
        drinkImageUrl = value;

        emit(SuccessUploadDrinkImageState());
      }).catchError((e) {
        emit(ErrorUploadDrinkImageState());
      });
    }).catchError((e) {
      emit(ErrorUploadDrinkImageState());
    });
  }

  OrderModel? orderModel;
  UserModel? doneUserModel;

  void orderDone({
    required OrderModel model,
  }) async {
    emit(LoadingOrderDoneState());
    if (model.isCold) {
      orderModel = OrderModel(
          price: model.price,
          isNewOrder: false,
          isCold: model.isCold,
          uId: model.uId,
          id: model.id,
          coldDrinkSugarType: model.coldDrinkSugarType,
          drinkName: model.drinkName,
          drinkImage: model.drinkImage,
          orderTime: model.orderTime,
          otherAdd: model.otherAdd);
      FirebaseFirestore.instance
          .collection('users')
          .doc(model.uId)
          .snapshots()
          .listen((event) {
        doneUserModel = UserModel.fromJson(event.data()!);
      });
      await FirebaseFirestore.instance
          .collection('usersDoneOrders')
          .doc(model.uId)
          .set(doneUserModel!.toMap())
          .then((value) async {
        await FirebaseFirestore.instance
            .collection('usersDoneOrders')
            .doc(model.uId)
            .collection('doneOrders')
            .doc('${orderModel!.id}')
            .set(orderModel!.toMap())
            .then((value) {
          emit(OrderDone());
        }).catchError((error) {
          // emit(ErrorAddDrinkState());
          print('Error is ${error.toString()}');
        });
      });

      emit(OrderDone());
    } else {
      if (model.drinkName == 'قهوة') {
        orderModel = OrderModel(
          price: model.price,
          isCold: model.isCold,
          isNewOrder: false,
          uId: model.uId,
          id: model.id,
          orderTime: model.orderTime,
          otherAdd: model.otherAdd,
          coffeeLevel: model.coffeeLevel,
          isDouble: model.isDouble,
          doubleGlassType: model.doubleGlassType,
          coffeeType: model.coffeeType,
          cSugarType: model.cSugarType,
          sCGlassType: model.sCGlassType,
          drinkImage: model.drinkImage,
          drinkName: model.drinkName,
        );
        FirebaseFirestore.instance
            .collection('users')
            .doc(model.uId)
            .snapshots()
            .listen((event) {
          doneUserModel = UserModel.fromJson(event.data()!);
        });
        await FirebaseFirestore.instance
            .collection('usersDoneOrders')
            .doc(model.uId)
            .set(doneUserModel!.toMap())
            .then((value) async {
          await FirebaseFirestore.instance
              .collection('usersDoneOrders')
              .doc(model.uId)
              .collection('doneOrders')
              .doc('${orderModel!.id}')
              .set(orderModel!.toMap())
              .then((value) {
            emit(OrderDone());
          }).catchError((error) {
            print('Error is ${error.toString()}');
          });
        });
        emit(OrderDone());
      } else {
        orderModel = OrderModel(
            price: model.price,
            isNewOrder: false,
            isCold: model.isCold,
            uId: model.uId,
            id: model.id,
            drinkName: model.drinkName,
            drinkImage: model.drinkImage,
            orderTime: model.orderTime,
            drinkType: model.drinkType,
            glassType: model.glassType,
            sugarType: model.sugarType,
            drinkQuantity: model.drinkQuantity,
            otherAdd: model.otherAdd);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(model.uId)
            .get()
            .then((event) async {
          doneUserModel = UserModel.fromJson(event.data()!);
        }).then((value) async {
          await FirebaseFirestore.instance
              .collection('usersDoneOrders')
              .doc(model.uId)
              .set(doneUserModel!.toMap())
              .then((value) async {
            await FirebaseFirestore.instance
                .collection('usersDoneOrders')
                .doc(model.uId)
                .collection('doneOrders')
                .doc('${orderModel!.id}')
                .set(orderModel!.toMap())
                .then((value) {
              emit(OrderDone());
            }).catchError((error) {
              print('Error is ${error.toString()}');
            });
          });
        });

        emit(OrderDone());
      }
    }
  }

  List<OrderModel> newOrders = [];

  List<OrderModel> doneOrders = [];

  void getNewOrders() async {
    emit(LoadingGetOrdersDataState());
    FirebaseFirestore.instance
        .collection('orders')
        .orderBy('orderTime')
        .snapshots()
        .listen((event) {
      newOrders = [];
      for (var order in event.docs) {
        newOrders.add(OrderModel.fromJson(order.data()));
        print(newOrders.length);
      }
      emit(SuccessGetOrdersDataState());
    });
  }

  void deleteNewOrder({required OrderModel model}) async {
    emit(NewOrderDeleteLoading());
    await FirebaseFirestore.instance
        .collection('orders')
        .doc('${model.id}')
        .delete()
        .then((value) {
      getUsersDetails(uId: model.uId);
    });
    emit(NewOrderDeleteDone());
  }

  void getDoneUsers() async {
    emit(LoadingGetDoneUsersState());
    FirebaseFirestore.instance
        .collection('usersDoneOrders')
        .snapshots()
        .listen((event) {
      doneUsers = [];
      for (var user in event.docs) {
        doneUsers.add(UserModel.fromJson(user.data()));
        print('user is ${doneUsers.length}');
        // doneUserIndex!=null?deleteBilledUsers(doneUserIndex!):null;
        emit(SuccessGetDoneUsersState());
      }
    });
  }
  int? doneUserIndex;
  OrderModel? doneOrderModel;
  List<int> totalAmount = [];
  int total = 0;

  void getUserDoneOrders({required String uId}) async {

    FirebaseFirestore.instance
        .collection('usersDoneOrders')
        .doc(uId)
        .snapshots()
        .listen((event) {
      event.reference.collection('doneOrders').snapshots().listen((event) {
        doneOrders = [];
        totalAmount = [];

        for (var order in event.docs) {
          doneOrderModel = OrderModel.fromJson(order.data());
          doneOrders.add(OrderModel.fromJson(order.data()));
          totalAmount.add(OrderModel.fromJson(order.data()).price);
          total = totalAmount.sum;
        }
      });

    });
  }

  UserModel? userDetails;
  List<UserModel> doneUsers = [];

  void getUsersDetails({required String uId}) async {
    emit(LoadingGetUserDetailsState());
    FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .snapshots()
        .listen((value) {
      userDetails = UserModel.fromJson(value.data()!);
      emit(SuccessGetUserDetailsState());
    });
  }

  int selected = 0;

  void expansionChangSelected(int s) {
    emit(LoadingChangeSelectedState());
    selected = s;
    emit(SuccessChangeSelectedState());
  }

  Map<int, bool> isChecked = {};
  List<int> checkedItems = [];

  void checkBoxClicked(int index) {
    if (isChecked[index] == null) {
      isChecked[index] = false;
    }
    isChecked[index] = !isChecked[index]!;
    if (isChecked[index] == true) {
      checkedItems.add(index);
    } else {
      checkedItems.remove(index);
    }
    print(checkedItems.toString());
    emit(CheckedState());
  }

  bool? isAllChecked;

  void allCheckBoxClicked() {
    isAllChecked ??= false;
    isAllChecked = !isAllChecked!;
    if (!isAllChecked!) {
      checkedItems = [];
    } else {
      checkedItems = [];
      doneOrders.forEach((element) {
        checkedItems.add(element.id);
      });
    }
    print(checkedItems.toString());
    emit(CheckedState());
  }

  int counter = 0;

  void billedOrders({required String uId}) {
    // counter = checkedItems.length+1;
    print(counter + checkedItems.length);
    emit(LoadingBillOrdersState());
    FirebaseFirestore.instance.collection('ordersCount').doc().set({
      'counter': checkedItems.length.toString(),
      'date': DateFormat.MEd().add_jm().format(DateTime.now())
    }).then((value) {
      counter = 0;
      FirebaseFirestore.instance
          .collection('usersDoneOrders')
          .doc(uId)
          .snapshots()
          .listen((event) {
        checkedItems.forEach((element) {
          event.reference
              .collection('doneOrders')
              .doc('$element')
              .delete()
              .then((value) {
            checkedItems = [];
          });
        });
      });
    });
    getUserDoneOrders(uId: uId);
    getDoneUsers();
    emit(SuccessBillOrdersState());
  }

  void deleteBilledUsers(int index){
    doneUsers.removeAt(index);
  }
}
