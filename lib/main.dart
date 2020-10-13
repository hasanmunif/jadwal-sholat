import 'package:flutter/material.dart';
import 'package:jadwal_sholat/models/waktu_solat.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Jadwal Sholat",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Position userLocation;
  Placemark userAddress;

  double lat_value = -6.4932879;
  double long_value = 107.0056517;
  String address = "Kota Bogor";

  List<String> _prayerTimes = [];
  List<String> _prayerNames = [];
  List initData = [];

  @override
  void initState() {
    super.initState();

    getSP().then((value) {
      initData = value;
      getPrayerTimes(lat_value, long_value);
      getAddress(lat_value, long_value);
    });
  }

  void setSP() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    pref.setDouble('key_lat', userLocation.latitude);
    pref.setDouble('key_long', userLocation.longitude);
    pref.setString('key_address', " ${userAddress.subAdministrativeArea} " " ${userAddress.country} ");
  }

  Future <Position> _getLocation() async {
    var currentLocation;

    try {
      currentLocation = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best
      );
    } catch(e) {
      currentLocation = null;
    }
    return currentLocation;
  }

  Future <dynamic> getSP() async {
    List dataPref = [];
    SharedPreferences pref = await SharedPreferences.getInstance();

    lat_value = pref.getDouble('key_lat');
    long_value = pref.getDouble('key_long');
    address = pref.getString('key_address');

    dataPref.add(lat_value);
    dataPref.add(long_value);
    dataPref.add(address);

    return dataPref;
  }

  getAddress(double lat, double long) async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(lat, long);
      Placemark place = p[0];
      userAddress = place;
    } catch(e) {
      userAddress = null;
    }
  }

  getPrayerTimes(double lat, double long) {
    PrayerTime prayer = new PrayerTime();

    prayer.setTimeFormat(prayer.getTime12());
    prayer.setCalcMethod(prayer.getMWL());
    prayer.setAsrJuristic(prayer.getShafii());
    prayer.setAdjustHighLats(prayer.getAdjustHighLats());

    List<int> offsets = [-6, 0, 3, 2, 0, 3, 6];

    String tmx = "${DateTime.now().timeZoneOffset}";

    var currentTime = DateTime.now();
    var timeZone = double.parse(tmx[0]);

    prayer.tune(offsets);

    setState(() {
      _prayerTimes = prayer.getPrayerTimes(currentTime, lat, long, timeZone);
      _prayerNames = prayer.getTimeNames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: ListView(
        children: <Widget>[
          SafeArea(
              child: Container(
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    Container(
                      // width: double.infinity
                      child:  Image.asset("assets/img/mosque.png"),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: ListView.builder(
                          itemCount: _prayerNames.length,
                          itemBuilder: (context, position) {
                            return Container(
                              padding: EdgeInsets.all(5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    child: Text(_prayerNames[position],
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    width: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(5)),
                                      color: Colors.white,
                                    ),
                                    child: Text(
                                      _prayerTimes[position],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                      ),
                    ),
                    SizedBox(height: 10,),
                    FlatButton.icon(
                        onPressed: () {
                          _getLocation().then((value) {
                            setState(() {
                              userLocation = value;
                              getPrayerTimes(userLocation.latitude, userLocation.longitude);
                              getAddress(userLocation.latitude, userLocation.longitude);
                              address = " ${userAddress.subAdministrativeArea} " " ${userAddress.country} ";
                            });
                            setSP();
                          });
                        },
                        icon: Icon(
                          Icons.location_on,
                          color: Colors.white,
                        ),
                        label: Text(
                          address ?? "Mencari Lokasi ...",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14
                          ),
                        )
                    )
                  ],
                ),
              )
          ),
        ],
      ),
    );
  }
}