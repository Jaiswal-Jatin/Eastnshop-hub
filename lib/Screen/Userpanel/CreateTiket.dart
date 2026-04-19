
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Constants/app_colors.dart';
import 'UserDashboard/HelpCenter/CreateTicket.dart';

class CreateTicket extends StatefulWidget {
  const CreateTicket({super.key});

  @override
  State<CreateTicket> createState() => _CreateTicketState();
}

class _CreateTicketState extends State<CreateTicket> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    setState(() {
      _emailController.text = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
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
                          Row(
                            children: [
                              Icon(Icons.arrow_back),
                              Spacer(),
                              Text('Help Center',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: 20,),
                          Text('Create ticket',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
                          SizedBox(height: 10,),
                          Column(
                            children: [
                              Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit.',style: TextStyle(fontWeight: FontWeight.normal,fontSize: 10),),
                              Text('consectetur adipiscing elit.',style: TextStyle(fontWeight: FontWeight.normal,fontSize: 10),),
                            ],
                          ),
                          SizedBox(height: 20,),
                          customTextFieldWidget(controller: _emailController, hintText: 'Email address', readOnly: true),
                          
                          SizedBox(height: 20,),
                          customTextFieldWidget(hintText: 'Full Name'),
                          Row(
                            children: [
                              Text(' Please enter your complete name.',style: TextStyle(fontWeight: FontWeight.normal,fontSize: 10),),
                              Spacer()
                            ],
                          ),
                           SizedBox(height: 20,),
                          customTextFieldWidget(hintText: 'Mobile Number'),
                          Row(
                            children: [
                              Text(' Please enter your active number',style: TextStyle(fontWeight: FontWeight.normal,fontSize: 10),),
                              Spacer()
                            ],
                          ),
                          SizedBox(height: 20,),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Concern Catergory',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                            ],
                          ),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Please select the closest possible category among the choices',style: TextStyle(fontWeight: FontWeight.normal,fontSize: 10),),
                            ],
                          ),
                           SizedBox(height: 20,),
                           TextField(
                            //: controller,
                            decoration: InputDecoration(
                              hintText: "Select a Category",
                              hintStyle: TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              suffixIcon: Icon(Icons.keyboard_arrow_down_outlined),
                            ),
                          ),
                           SizedBox(height: 20,),
                           Column(
                            children: [
                              Text('Explain your concern. Include all the detail related to the',style: TextStyle(fontWeight: FontWeight.normal,fontSize: 10),),
                              Text('concern to help speed up fixing your problem',style: TextStyle(fontWeight: FontWeight.normal,fontSize: 10),),
                            ],
                          ),
                           SizedBox(height: 20,),
                          customTextFieldWidget(hintText: 'Write Something'),
                          
                          
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey,width: 1),
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Center(child: Text('Attach a file',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),)),
                                ),
                              ),
                            ],
                          ),
                          Text('Add file or drop files here',style: TextStyle(fontSize: 10),)
                          ,SizedBox(height: 20,),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>Ticketcreated())),
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed,
                                      //border: Border.all(color: Colors.grey,width: 1),
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Center(child: Text('Submit the Ticket',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 20),)),
                                  ),
                                ),
                              ),
                            ],
                          )
                          
                ],
              ),
            ),  
           // Spacer(),
            Image.asset('assets/footer.png'),
          ],
        ),
      ),
    );
  }
    customTextFieldWidget({ TextEditingController? controller,required String hintText, bool readOnly = false }) {
    return Stack(
  children: [
    // The TextField
    SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
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
