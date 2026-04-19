
import 'package:get/get.dart';

import '../Controllers/FavoritesController.dart';
import '../Controllers/LoginController.dart';
import '../Controllers/NearbyOffersController.dart';
import '../Controllers/OfferDetailsController.dart';
import '../Controllers/ticketListController.dart';

class SignUpBinding extends Bindings{

  @override
  void dependencies(){
    Get.lazyPut<LoginController>(()=> LoginController());
  }
}

class LoginBinding extends Bindings{

 @override
  void dependencies(){
    Get.lazyPut<LoginController>(()=> LoginController());
    Get.lazyPut<FavoritesController>(()=> FavoritesController());
    Get.lazyPut<NearbyOffersController>(()=> NearbyOffersController());
    Get.lazyPut<OfferDetailsController>(()=> OfferDetailsController());
  }
}

class TicketListBinding extends Bindings{

 @override
  void dependencies(){
    Get.lazyPut<TicketListController>(()=> TicketListController());
  }
}
