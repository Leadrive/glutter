import 'package:flutter/material.dart';
import 'package:glutter/models/shared/profile.dart';
import 'package:glutter/services/shared/database_service.dart';
import 'package:glutter/services/shared/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSelector extends StatefulWidget {
  @override
  _ProfileSelectorState createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends State<ProfileSelector> {

    Future profilesFuture;
    Profile selectedProfile;
    Future prefService;
    int lastProfileId;

    @override
    void initState() {
        super.initState();

        profilesFuture = DatabaseService.db.getProfiles();

        PreferencesService.getLastProfile().then((profile) =>
            this.setState(() {
                this.selectedProfile = profile;
                //print("print1 (getLastProfile.then): SelectedProfile = " + this.selectedProfile.toString());
            })
        );
        //print("print2 (end of initState): SelectedProfile = " + this.selectedProfile.toString());
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            child: FutureBuilder(
                future: profilesFuture,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                    switch (snapshot.connectionState) {
                        case ConnectionState.active:
                        case ConnectionState.waiting:
                            return Center(
                                child: Container(
                                    child: new CircularProgressIndicator(),
                                    alignment: Alignment(
                                        0.0, 0.0
                                    )
                                )
                            );
                        case ConnectionState.done:
                            return new Container(
                                child: selectedProfile != null ? DropdownButton<Profile>(
                                    items: snapshot.data.map((Profile item) {
                                        return DropdownMenuItem<Profile>(
                                            value: item,
                                            child: Text(item.caption + " (" + item.serverAddress + ")")
                                        );
                                    }).cast<DropdownMenuItem<Profile>>().toList(),
                                    onChanged: (Profile newSelectedProfile) {
                                        setState(() {
                                            selectedProfile = newSelectedProfile;
                                            PreferencesService.setLastProfileId(newSelectedProfile.id);
                                        });
                                    },
                                    value: selectedProfile,
                                ) : CircularProgressIndicator()
                            );
                        default:
                            return Text("default");
                    }
                }
            ),
        );
    }
}
