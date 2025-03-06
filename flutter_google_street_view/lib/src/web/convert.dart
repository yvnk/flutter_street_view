import 'dart:async';
import 'dart:core';
import 'dart:js_interop';

import 'package:google_maps/google_maps.dart' as gmaps;
import 'package:google_maps/google_maps_streetview.dart' as sv;

/// Convert StreetViewPanoramaOptions to StreetViewPanoramaOptions of gmap
Future<sv.StreetViewPanoramaOptions> toStreetViewPanoramaOptions(Map<String, dynamic> arg,
    {sv.StreetViewPanorama? current}) async {
  final result = sv.StreetViewPanoramaOptions();
  String? errorMsg;
  var request;
  double? raduis = arg['radius'] as double?;
  String? source = arg['source'] as String?;
  gmaps.LatLng? location;
  String? pano;
  if (arg['panoId'] != null) {
    pano = arg['panoId'];
    request = sv.StreetViewPanoRequest()..pano = pano;
  } else {
    location = gmaps.LatLng(arg['position'][0], arg['position'][1]);
    final sourceTmp = source == "outdoor" ? sv.StreetViewSource.OUTDOOR : sv.StreetViewSource.DEFAULT;
    request = sv.StreetViewLocationRequest()
      ..location = location
      ..radius = raduis
      ..source = sourceTmp;
  }
  Completer<bool> check = Completer();

  void error(sv.StreetViewPanoramaData? data, status) {
    final bool find = (status.toString() == "OK");
    if (find) {
      if (location != null) {
        result.position = data!.location!.latLng;
      } else {
        result.pano = data!.location!.pano;
      }
    } else {
      errorMsg = location != null
          ? "Oops..., no valid panorama found with position:${location.lat}, ${location.lng}, try to change `position`, `radius` or `source`."
          : pano != null
              ? "Oops..., no valid panorama found with panoId:$pano, try to change `panoId`."
              : "setPosition, catch unknown error.";
    }
    check.complete(find);
  }

  sv.StreetViewService().getPanorama(request);
  await check.future;

  result.showRoadLabels = arg['streetNamesEnabled'] as bool? ?? true;
  result.clickToGo = arg['clickToGo'] as bool? ?? true;
  result.zoomControl = arg['zoomControl'] as bool? ?? true;

  result.addressControl = arg['addressControl'] as bool? ?? true;
  result.addressControlOptions = toStreetViewAddressControlOptions(arg);
  result.disableDefaultUI = arg['disableDefaultUI'] as bool? ?? true;
  result.disableDoubleClickZoom = arg['disableDoubleClickZoom'] as bool? ?? true;
  result.enableCloseButton = arg['enableCloseButton'] as bool? ?? true;
  result.fullscreenControl = arg['fullscreenControl'] as bool? ?? true;
  result.fullscreenControlOptions = toFullscreenControlOptions(arg);
  result.linksControl = arg['linksControl'] as bool? ?? true;
  result.motionTracking = arg['motionTracking'] as bool? ?? true;
  result.motionTrackingControl = arg['motionTrackingControl'] as bool? ?? true;
  result.motionTrackingControlOptions = toMotionTrackingControlOptions(arg);
  result.scrollwheel = arg['scrollwheel'] as bool? ?? true;
  result.panControl = arg['panControl'] as bool? ?? true;
  result.panControlOptions = toPanControlOptions(arg);
  result.zoomControlOptions = toZoomControlOptions(arg);
  result.visible = arg['visible'] as bool? ?? true;

  final currentPov = current?.pov;
  result.pov = sv.StreetViewPov()
    ..heading = arg['bearing'] ?? currentPov?.heading ?? 0
    ..pitch = arg['tilt'] ?? currentPov?.pitch ?? 0;
  result.zoom = arg['zoom'] as double?;
  if (errorMsg != null) {
    throw NoStreetViewException(options: result, errorMsg: errorMsg!);
  } else {
    return result;
  }
}

sv.StreetViewSource toStreetSource(Map<String, dynamic> arg) {
  final source = arg['source'];
  return source == "outdoor" ? sv.StreetViewSource.OUTDOOR : sv.StreetViewSource.DEFAULT;
}

sv.StreetViewAddressControlOptions? toStreetViewAddressControlOptions(dynamic arg) {
  final pos = arg is Map ? arg["addressControlOptions"] : arg;
  return sv.StreetViewAddressControlOptions()..position = toControlPosition(pos);
}

gmaps.FullscreenControlOptions? toFullscreenControlOptions(dynamic arg) {
  final pos = arg is Map ? arg["fullscreenControlOptions"] : arg;
  return gmaps.FullscreenControlOptions()..position = toControlPosition(pos);
}

gmaps.MotionTrackingControlOptions? toMotionTrackingControlOptions(dynamic arg) {
  final pos = arg is Map ? arg["motionTrackingControlOptions"] : arg;
  return gmaps.MotionTrackingControlOptions()..position = toControlPosition(pos);
}

gmaps.PanControlOptions? toPanControlOptions(dynamic arg) {
  final pos = arg is Map ? arg["panControlOptions"] : arg;
  return gmaps.PanControlOptions()..position = toControlPosition(pos);
}

gmaps.ZoomControlOptions? toZoomControlOptions(dynamic arg) {
  final pos = arg is Map ? arg["zoomControlOptions"] : arg;
  return gmaps.ZoomControlOptions()..position = toControlPosition(pos);
}

gmaps.ControlPosition? toControlPosition(String? position) {
  return position == "bottom_center"
      ? gmaps.ControlPosition.BOTTOM_CENTER
      : position == "bottom_left"
          ? gmaps.ControlPosition.BOTTOM_LEFT
          : position == "bottom_right"
              ? gmaps.ControlPosition.BOTTOM_RIGHT
              : position == "left_bottom"
                  ? gmaps.ControlPosition.LEFT_BOTTOM
                  : position == "left_center"
                      ? gmaps.ControlPosition.LEFT_CENTER
                      : position == "left_top"
                          ? gmaps.ControlPosition.LEFT_TOP
                          : position == "right_bottom"
                              ? gmaps.ControlPosition.RIGHT_BOTTOM
                              : position == "right_center"
                                  ? gmaps.ControlPosition.RIGHT_CENTER
                                  : position == "right_top"
                                      ? gmaps.ControlPosition.RIGHT_TOP
                                      : position == "top_center"
                                          ? gmaps.ControlPosition.TOP_CENTER
                                          : position == "top_left"
                                              ? gmaps.ControlPosition.TOP_LEFT
                                              : position == "top_right"
                                                  ? gmaps.ControlPosition.TOP_RIGHT
                                                  : null;
}

Map<String, dynamic> streetViewPanoramaLocationToJson(sv.StreetViewPanorama panorama) => linkToJson(panorama.links)
  ..["panoId"] = panorama.pano
  ..addAll(positionToJson(panorama.position));

Map<String, dynamic> streetViewPanoramaCameraToJson(sv.StreetViewPanorama panorama) =>
    {"bearing": panorama.pov.heading, "tilt": panorama.pov.pitch, "zoom": panorama.zoom};

Map<String, dynamic> positionToJson(gmaps.LatLng? position) => {
      "position": (position != null ? [position.lat, position.lng] : null)
    };

Map<String, dynamic> linkToJson(JSArray<sv.StreetViewLink?>? links) {
  List links1 = [];
  if (links != null) {
    links.toDart.forEach((l) {
      if (l != null) links1.add([l.pano, l.heading]);
    });
  }
  return {"links": links1};
}

class NoStreetViewException implements Exception {
  final sv.StreetViewPanoramaOptions options;
  final String errorMsg;

  NoStreetViewException({required this.options, required this.errorMsg});
}
