/// Google Maps styles for the navigation map.
///
/// The same quiet base as the customer's tracking map: shop pins, bus stops
/// and brand colours hidden so the route is what the eye lands on. Street
/// names stay, because a rider reads them against the signs.
const String kNavMapStyleLight = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f5f2"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b7065"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f2"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#e3eed6"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#7a8074"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#fbe6c8"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#f1d3a6"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#9a9f94"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cfe3ee"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#8aa7b6"}]}
]
''';

const String kNavMapStyleDark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1b1e19"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8d9387"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1b1e19"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#22301b"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c3128"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#353b30"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#4a4234"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#6b7166"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#10202a"}]}
]
''';
