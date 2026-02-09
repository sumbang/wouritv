import 'package:flutter/material.dart';

class Date extends StatelessWidget {

final String label;
final Color background;
final TextEditingController controller;
final Icon icon;
final TextEditingController controller2;

  const Date({super.key, 
    required this.label,
    required this.background,
    required this.controller,
    required this.icon,
    required this.controller2
  });
  
  @override
  Widget build(BuildContext context) {

    DateTime datenaiss = DateTime.now();

    return  Padding(
              padding: const EdgeInsets.all(0.0),
              child: Container(
                padding: const EdgeInsets.only(
                    left: 10.0, right: 5.0, top: 3.0, bottom: 3.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  border: Border.all(color: Colors.white),
                ),
                child: TextFormField(
                  onTap: () {
                    showDatePicker(
                            context: context,
                            initialEntryMode: DatePickerEntryMode.calendarOnly,
                             locale: const Locale("fr", "FR"),
                            initialDate: datenaiss,
                            firstDate: DateTime(1900),
                            //locale: Locale("fr","FR"),
                            lastDate: DateTime.now())
                        .then((date) {
                          if(date != null) {
                        datenaiss = date;
                        String vj = "";
                        String vm = "";
                        var date1 = DateTime.parse(datenaiss.toString());
                        var j = date1.day;
                        var m = date1.month;
                        if (j < 10)
                          vj = "0" + j.toString();
                        else
                          vj = j.toString();
                        if (m < 10)
                          vm = "0" + m.toString();
                        else
                          vm = m.toString();
                        var formattedDate = "${date1.year}-${vm}-${vj}";
                        var formattedDate1 = "${vj}/${vm}/${date1.year}";
                        controller.text = formattedDate1;
                        controller2.text = formattedDate;
                          }
                    });
                  },
                  obscureText: false,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: icon,
                    labelText: label,
                    labelStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                        fontWeight: FontWeight.normal),
                  ),
                  keyboardType: TextInputType.text,
                  enabled: true,
                  controller: controller,
                ),
              ),
            );
    
   
  }


}