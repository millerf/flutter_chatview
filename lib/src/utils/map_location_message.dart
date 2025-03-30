import 'package:chatview/chatview.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

const String mapLocationPrefix = 'map-location';
const String regExpMapLocation = '$mapLocationPrefix:()-()';
const String doubleRegExp = r'(-?\d+\.\d+)';

String locationMessageFromLocation(LatLng location) {
  return regExpMapLocation
      .replaceFirst('()', location.latitude.toString())
      .replaceFirst('()', location.longitude.toString());
}

bool isLocationMessage(Message message) {
  return message.messageType == MessageType.text &&
      message.message.startsWith(mapLocationPrefix);
}

LatLng? getLocationFromMessage(Message message) {
  RegExp pattern = RegExp(regExpMapLocation
      .replaceFirst('()', doubleRegExp)
      .replaceFirst('()', doubleRegExp));
  final match = pattern.firstMatch(message.message);
  if (match != null) {
    final firstDouble = double.parse(match.group(1)!);
    final secondDouble = double.parse(match.group(2)!);
    return LatLng(firstDouble, secondDouble);
  }

  return null;
}
