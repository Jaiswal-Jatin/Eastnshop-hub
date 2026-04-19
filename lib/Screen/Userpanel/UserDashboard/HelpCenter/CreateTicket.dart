
import 'package:flutter/material.dart';

import '../../../../Constants/app_colors.dart';
import '../../CreateTiket.dart';
import '../../FAQPage.dart';

class Ticketcreated extends StatefulWidget {
  const Ticketcreated({super.key});

  @override
  State<Ticketcreated> createState() => _TicketcreatedState();
}

class _TicketcreatedState extends State<Ticketcreated> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20,top: 30,right: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset('assets/menu.png',),
                    SizedBox(width: 10,),
                    Image.asset('assets/Shopkeeper_logo.png',height: 50,width: 50,),
                    Spacer(),
                    SizedBox(height: 30,width: 80,child: Image.asset('assets/btn-shop.png',fit: BoxFit.fill,)),
                    SizedBox(width: 5,),
                    Image.asset('assets/ico-search 1.png',height: 20,width: 20,),
                    SizedBox(width: 5,),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade600,width: 2),
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.grey.shade200
                      ),
                      child: Image.asset("assets/profile-man.png"),
                    ),
                  ],
                ),
                Divider(color: Colors.grey,),
                InkWell(
                  onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>FAQPage())),
                  child: Image.asset('assets/content (1).png',
                  fit: BoxFit.fill,height: MediaQuery.of(context).size.height/1.45,width: MediaQuery.of(context).size.width,
                  ),
                )
              ],
            ),
          ),  
          Spacer(),
          InkWell(
            onTap:()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>CreateTicket())),child: Image.asset('assets/footer.png')),
        ],
      ),
    );
  }
    customTextFieldWidget({ TextEditingController? controller,required String hintText}) {
    return Stack(
  children: [
    // The TextField
    TextField(
      controller: controller,
      style: const TextStyle(color: Colors.grey),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
      ),
    ),

    // Asterisk in top-right
    Positioned(
      top: 2,
      right: 15,
      child: Text(
        '*',
        style: TextStyle(
          fontSize: 20,
          color: AppColors.primaryRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
);

        
  }

}
