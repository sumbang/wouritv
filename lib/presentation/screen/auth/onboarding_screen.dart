import 'package:flutter/material.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/config/sizeconfig.dart';
import 'package:wouritv/presentation/component/widget/bouton.dart';
import 'package:wouritv/presentation/screen/auth/login_screen.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class OnboardingScreen extends HookConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(body : SingleChildScrollView(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(),
                  child: Stack(children: [
                    Container(
                      height: 100 * SizeConfig.heightMultiplier,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/img/bg.png"),
                              fit: BoxFit.cover),  
                          ),
                      child: Container(),
                    ),
                     Container(
                      height: 100 * SizeConfig.heightMultiplier,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        gradient: LinearGradient(
                          colors: [Colors.black, Colors.black.withOpacity(0.1)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.1,1.0]
                        )
                      ),
                      child: Container(),
                    ),
                    Padding(
                        padding: EdgeInsets.only(
                            top: 60 * SizeConfig.heightMultiplier,
                            left: 15.0,
                            right: 15.0),
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Divider(
                                height: 20.0,
                                color: Colors.transparent,
                              ),
                              Text(
                                AppLocalizations.of(context)!.app_title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25.0,
                                    fontFamily: 'Candara',
                                    color: Setting.white),
                                textAlign: TextAlign.center,
                              ),
                              const Divider(
                                height: 10.0,
                                color: Colors.transparent,
                              ),
                              Text(
                                AppLocalizations.of(context)!.app_description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    fontFamily: 'Candara',
                                    height: 1.5,
                                    color: Setting.white),
                                textAlign: TextAlign.justify,
                              ),
                              const Divider(
                                height: 15.0,
                                color: Colors.transparent,
                              ),
                              Bouton(background: Setting.primaryColor, 
                              couleur: Setting.white, 
                              onTap: () { Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    LoginScreen()),
                                          ); }, 
                              texte: AppLocalizations.of(context)!.home_bt,) 
                            ],
                          ),
                        ))
                  ]))));
  }

}